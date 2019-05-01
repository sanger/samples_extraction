require 'token_util'

class FactChanges
  attr_accessor :facts_to_destroy, :facts_to_add, :assets_to_create, :assets_to_destroy,
    :assets_to_add, :assets_to_remove, :wildcards, :instances_from_uuid

  def initialize(json=nil)
    reset
    parse_json(json) if json
  end

  def reset
    @facts_to_destroy = []
    @facts_to_add = []
    @assets_to_create = []
    @assets_to_destroy = []
    @assets_to_add = []
    @assets_to_remove = []

    @instances_from_uuid = {}
    @wildcards = {}
  end

  def parse_json(json)
    obj = JSON.parse(json)
    ['create_asset', 'create_group', 'destroy_group', 'remove_facts', 'add_facts', 'remove_asset', 'add_asset', 'destroy_asset'].reduce(FactChanges.new) do |updates, action_type|
      if obj[action_type]
        updates.merge(send(action_type, obj[action_type]))
      else
        updates
      end
    end
  end

  def add(s,p,o, options=nil)
    detected = (s && p && o) && facts_to_add.detect do |triple|
      (triple[0]==s) && (triple[1] ==p) && (triple[2] == o)
    end
    t = [s,p,o, options]
    params = {asset: t[0], predicate: t[1], literal: !(t[2].kind_of?(Asset))}
    params[:literal] ? params[:object] = t[2] : params[:object_asset] = t[2]
    params = params.merge(t[3]) if t[3]

    facts_to_add.push(params) unless detected
  end

  def add_facts(listOfLists)
    listOfLists.each{|list| add(list[0], list[1], list[2])}
    self
  end

  def remove_facts(listOfLists)
    listOfLists.each{|list| remove_where(list[0], list[1], list[2])}
    self
  end

  def add_remote(s,p,o)
    add(s,p,o,is_remote?: true) if (s && p && o)
  end

  def remove(f)
    facts_to_destroy.push(f)
  end

  def remove_where(subject, predicate, object)
    subject = find_asset(subject)
    object = find_asset(object)

    if object.kind_of? String
      elems = Fact.where(asset: subject, predicate: predicate, object: object)
    else
      elems = Fact.where(asset: subject, predicate: predicate, object_asset: object)
    end
    facts_to_destroy.concat(elems).uniq!
  end


  def merge(fact_changes)
    if (fact_changes)
      assets_to_create.concat(fact_changes.assets_to_create).uniq!
      facts_to_add.concat(fact_changes.facts_to_add).uniq!
      assets_to_add.concat(fact_changes.assets_to_add).uniq!
      assets_to_remove.concat(fact_changes.assets_to_remove).uniq!
      facts_to_destroy.concat(fact_changes.facts_to_destroy).uniq!
      assets_to_destroy.concat(fact_changes.assets_to_destroy).uniq!
    end
    self
  end

  def apply(step, with_operations=true)
    ActiveRecord::Base.transaction do |t|
      operations = [
        _create_assets(step, assets_to_create, with_operations),
        _create_facts(step, facts_to_add, with_operations),
        _add_assets(step, assets_to_add, with_operations),
        _remove_assets(step, assets_to_remove, with_operations),
        _remove_facts(step, facts_to_destroy, with_operations),
        _delete_assets(step, assets_to_destroy, with_operations)
      ].flatten.compact
      Operation.import(operations) unless operations.empty?
      reset
    end
  end

  def find_asset(asset_or_uuid)
    find_instance_of_class_by_uuid(Asset, asset_or_uuid)
  end

  def find_asset_group(asset_group_or_id)
    find_instance_of_class_by_uuid(AssetGroup, asset_group_or_id)
  end

  def find_assets(assets_or_uuids)
    assets_or_uuids.uniq.map { |asset_or_uuid| find_instance_of_class_by_uuid(Asset, asset_or_uuid) }
  end

  def build_assets(assets)
    assets.uniq.map { |asset_or_uuid| find_instance_of_class_by_uuid(Asset, asset_or_uuid, true) }
  end

  def find_instance_of_class_by_uuid(klass, instance_or_uuid_or_id, create=false)
    if TokenUtil.is_wildcard?(instance_or_uuid_or_id)
      uuid = uuid_for_wildcard(instance_or_uuid_or_id)
      found = find_instance_from_uuid(klass, uuid)
      if !found && create
        found = ((instances_from_uuid[uuid] ||= klass.new(uuid: uuid)))
      end
    elsif TokenUtil.is_uuid?(instance_or_uuid_or_id)
      found = find_instance_from_uuid(klass, instance_or_uuid_or_id)
      if !found && create
        found = ((instances_from_uuid[instance_or_uuid_or_id] ||= klass.new(uuid: instance_or_uuid_or_id)))
      end
    else
      found = instance_or_uuid_or_id
    end

    raise StandardError.new(found) if found.nil?

    found
  end

  def uuid_for_wildcard(wildcard)
    wildcards[wildcard] ||= SecureRandom.uuid
  end

  def find_instance_from_uuid(klass, uuid)
    found = klass.find_by(uuid:uuid)
    return found if found
    instances_from_uuid[uuid]
  end


  def create_assets(assets)
    assets_to_create.concat(build_assets(assets)).uniq!
  end

  def delete_assets(assets)
    assets_to_destroy.concat(find_assets(assets)).uniq!
  end

  def add_assets(asset_group_id, assets)
    asset_group = find_asset_group(asset_group_id)
    assets = find_assets(assets)
    assets_to_add.concat(assets.map{|asset| { asset_group: asset_group, asset: asset} })
  end

  def remove_assets(asset_group_id, assets)
    asset_group = find_asset_group(asset_group_id)
    assets = find_assets(assets)
    assets_to_remove.concat(assets.map{|asset| AssetGroupsAsset.where(asset_group: asset_group, asset: asset)})
  end

  private

  def _add_assets(step, asset_group_assets, with_operations = true)
    _instance_builder_for_import(AssetGroupsAsset, asset_group_assets) do |instances|
      _asset_group_operations('selectAsset', step, instances) if with_operations
    end
  end

  def _remove_assets(step, asset_group_assets, with_operations = true)
    _instances_deletion(AssetGroupsAsset, asset_group_assets) do |asset_group_assets|
      _asset_operations('unselectAsset', step, asset_group_assets) if with_operations
    end
  end

  def _create_assets(step, assets, with_operations=true)
    return unless assets
    assets.each_with_index do |asset, index|
      asset.save
      if (asset.has_literal?('barcodeType', 'NoBarcode'))
        asset.update_attributes(:barcode => nil)
      else
        asset.generate_barcode(index)
      end
    end
    _asset_operations('createAsset', step, assets) if with_operations
  end

  def _delete_assets(step, assets, with_operations=true)
    _instances_deletion(Asset, assets) do |assets|
      _asset_operations('deleteAsset', step, assets) if with_operations
    end
    # return unless assets
    # ids_to_remove = assets.map(&:id)
    # if ids_to_remove && !ids_to_remove.empty?
    #   operations = _asset_operations('deleteAsset', step, assets) if with_operations
    #   Asset.where(id: ids_to_remove).destroy_all
    #   operations
    # end
  end

  def _create_facts(step, params_for_facts, with_operations=true)
    _instance_builder_for_import(Fact, params_for_facts) do |facts|
      _fact_operations('addFacts', step, facts) if with_operations
    end
  end


  def _remove_facts(step, facts, with_operations=true)
    _instances_deletion(Fact, facts) do
      _fact_operations('removeFacts', step, facts) if with_operations
    end
  end


  def _asset_group_operations(action_type, step, asset_group_assets)
    asset_group_assets.map do |asset_group_asset, index|
      Operation.new(:action_type => action_type, :step => step,
        :asset=> asset_group_asset.asset, object: asset_group_asset.asset_group.id)
    end
  end

  def _asset_operations(action_type, step, assets)
    assets.map do |asset, index|
      Operation.new(:action_type => action_type, :step => step,
        :asset=> asset, object: asset.uuid)
    end
  end

  def _fact_operations(action_type, step, facts)
    facts.map do |fact|
      Operation.new(:action_type => action_type, :step => step,
        :asset=> fact.asset, :predicate => fact.predicate, :object => fact.object, object_asset: fact.object_asset)
    end
  end

  def _instance_builder_for_import(klass, params_list, &block)
    instances = params_list.map do |params_for_instance|
      klass.new(params_for_instance) unless klass.exists?(params_for_instance)
    end.compact
    instances.each do |instance|
      instance.run_callbacks(:save) { false }
      instance.run_callbacks(:create) { false }
    end
    if instances && !instances.empty?
      klass.import(instances)
      yield instances
    end
  end

  def _instances_deletion(klass, instances, &block)
    operations = yield instances
    instances = [instances].flatten
    ids_to_remove = instances.map(&:id).compact.uniq

    klass.where(id: ids_to_remove).delete_all if ids_to_remove && !ids_to_remove.empty?
    operations
  end

end
