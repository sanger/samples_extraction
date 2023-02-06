require 'token_util'
require 'changes_support/disjoint_list'
require 'changes_support/transaction_scope'

class FactChanges # rubocop:todo Style/Documentation
  ACTIONS = %w[
    set_errors
    create_assets
    create_asset_groups
    delete_asset_groups
    remove_facts
    add_facts
    delete_assets
    add_assets
    remove_assets
  ].freeze

  include ChangesSupport::TransactionScope

  attr_accessor :facts_to_destroy,
                :facts_to_add,
                :assets_to_create,
                :assets_to_destroy,
                :assets_to_add,
                :assets_to_remove,
                :wildcards,
                :instances_from_uuid,
                :asset_groups_to_create,
                :asset_groups_to_destroy,
                :errors_added,
                :already_added_to_list,
                :instances_by_unique_id,
                :facts_to_set_to_remote,
                :operations

  def initialize(json = nil)
    @assets_updated = []
    reset
    parse_json(json) unless json.nil?
  end

  def reset
    @errors_added = []

    @facts_to_set_to_remote = []

    build_disjoint_lists(:facts_to_add, :facts_to_destroy)
    build_disjoint_lists(:assets_to_create, :assets_to_destroy)
    build_disjoint_lists(:asset_groups_to_create, :asset_groups_to_destroy)
    build_disjoint_lists(:assets_to_add, :assets_to_remove)

    @instances_from_uuid = {}
    @wildcards = {}
  end

  def build_disjoint_lists(list, opposite)
    list1 = ChangesSupport::DisjointList.new([])
    list2 = ChangesSupport::DisjointList.new([])

    list1.add_disjoint_list(list2)

    send("#{list}=", list1)
    send("#{opposite}=", list2)
  end

  def asset_group_asset_to_h(asset_group_asset_str)
    asset_group_asset_str
      .reduce({}) do |memo, o|
        key = (o[:asset_group] && o[:asset_group].uuid) || nil
        memo[key] = [] unless memo[key]
        memo[key].push(o[:asset].uuid)
        memo
      end
      .map { |k, v| [k, v] }
  end

  def to_h
    {
      set_errors: @errors_added,
      create_assets: @assets_to_create.map(&:uuid),
      create_asset_groups: @asset_groups_to_create.map(&:uuid),
      delete_asset_groups: @asset_groups_to_destroy.map(&:uuid),
      delete_assets: @assets_to_destroy.map(&:uuid),
      add_facts: @facts_to_add.map { |f| [f[:asset]&.uuid, f[:predicate], (f[:object] || f[:object_asset].uuid)] },
      remove_facts:
        @facts_to_destroy.map do |f|
          if f[:id]
            fact = Fact.find(f[:id])
            [fact.asset.uuid, fact.predicate, fact.object_value_or_uuid]
          else
            [f[:asset]&.uuid, f[:predicate], (f[:object] || f[:object_asset].uuid)]
          end
        end,
      add_assets: asset_group_asset_to_h(@assets_to_add),
      remove_assets: asset_group_asset_to_h(@assets_to_remove)
    }.reject { |_k, v| v.length == 0 }
  end

  def to_json(*_args)
    JSON.pretty_generate(to_h)
  end

  def parse_json(json)
    actions_data = json.is_a?(String) ? JSON.parse(json) : json.deep_stringify_keys
    actions_data
      .slice(*ACTIONS)
      .each_pair { |action_type, action_value| send(action_type, action_value) if action_value }
    true
  end

  def values_for_predicate(asset, predicate)
    actual_values = asset.facts.with_predicate(predicate).map(&:object)
    values_to_add = facts_to_add.select { |f| (f[:asset] == asset) && (f[:predicate] == predicate) }.pluck(:object)
    values_to_destroy =
      facts_to_destroy.select { |f| (f[:asset] == asset) && (f[:predicate] == predicate) }.pluck(:object)
    (actual_values + values_to_add - values_to_destroy)
  end

  def _build_fact_attributes(asset, predicate, object, options = {})
    literal = !(object.kind_of?(Asset))
    params = { asset: asset, predicate: predicate, literal: literal }
    literal ? params[:object] = object : params[:object_asset] = object
    params = params.merge(options) if options
    params
  end

  def add(s, p, o, options = {})
    s = find_asset(s)
    o = (options[:literal] == true) ? o : find_asset(o)

    fact = _build_fact_attributes(s, p, o, options)

    facts_to_add << fact if fact
  end

  def add_facts(list_of_lists)
    list_of_lists.each { |list| add(list[0], list[1], list[2]) }
    self
  end

  def remove_facts(list_of_lists)
    list_of_lists.each { |list| remove_where(list[0], list[1], list[2]) }
    self
  end

  def add_remote(s, p, o, options = {})
    add(s, p, o, options.merge({ is_remote?: true })) if s && p && o
  end

  def replace_remote(asset, predicate, object, options = {})
    if asset && predicate && object
      asset
        .facts
        .with_predicate(predicate)
        .each do |fact|
          remove(fact)

          # In case they are not removed, at least they will be set as remote
          facts_to_set_to_remote << fact
        end
      add_remote(asset, predicate, object, options)
    end
  end

  def remove(f)
    return if f.nil?

    if f.kind_of?(Enumerable)
      facts_to_destroy << f.map { |o| o.attributes.symbolize_keys }
    elsif f.kind_of?(Fact)
      facts_to_destroy << f.attributes.symbolize_keys
    end
  end

  def remove_where(subject, predicate, object)
    subject = find_asset(subject)
    object = find_asset(object)

    fact = _build_fact_attributes(subject, predicate, object)

    facts_to_destroy << fact if fact
  end

  def merge_hash(h1, h2)
    h2.keys.each { |k| h1[k] = h2[k] }
    h1
  end

  def merge(fact_changes)
    if fact_changes
      # To keep track of already added object after merging with another fact changes object
      # _add_already_added_from_other_object(fact_changes)
      errors_added.concat(fact_changes.errors_added)
      asset_groups_to_create.concat(fact_changes.asset_groups_to_create)
      assets_to_create.concat(fact_changes.assets_to_create)
      facts_to_add.concat(fact_changes.facts_to_add)
      assets_to_add.concat(fact_changes.assets_to_add)
      assets_to_remove.concat(fact_changes.assets_to_remove)
      facts_to_destroy.concat(fact_changes.facts_to_destroy)
      assets_to_destroy.concat(fact_changes.assets_to_destroy)
      asset_groups_to_destroy.concat(fact_changes.asset_groups_to_destroy)
      merge_hash(instances_from_uuid, fact_changes.instances_from_uuid)
      merge_hash(wildcards, fact_changes.wildcards)
    end
    self
  end

  def apply(step, with_operations = true)
    _handle_errors(step) if errors_added.length > 0
    ActiveRecord::Base.transaction do |_t|
      _set_remote_facts(facts_to_set_to_remote)
      operations = [
        _create_asset_groups(step, asset_groups_to_create, with_operations),
        _create_assets(step, assets_to_create, with_operations),
        _add_assets(step, assets_to_add, with_operations),
        _remove_assets(step, assets_to_remove, with_operations),
        _remove_facts(step, facts_to_destroy, with_operations),
        _detach_assets(step, assets_to_destroy, with_operations),
        _detach_asset_groups(step, asset_groups_to_destroy, with_operations),
        _create_facts(step, facts_to_add, with_operations)
      ].flatten.compact
      unless operations.empty?
        Operation.import(operations)
        @operations = operations
      end
      reset
    end
  end

  def assets_updated
    return [] unless @operations

    @assets_updated = Asset.where(id: @operations.pluck(:asset_id).uniq).distinct
  end

  # Consider removal once dpl348_decouple_automatic_printing_from_steps is finalised
  def assets_for_printing
    return [] unless @operations

    asset_ids = @operations.select { |operation| (operation.action_type == 'createAssets') }.pluck(:object).uniq

    ready_for_print_ids =
      @operations
        .select do |operation|
          (
            (operation.action_type == 'addFacts') && (operation.predicate == 'is') &&
              (operation.object == 'readyForPrint')
          )
        end
        .filter_map(&:asset)
        .uniq
        .map(&:uuid)

    ids_for_print = asset_ids.concat(ready_for_print_ids).flatten.uniq
    @assets_for_printing = Asset.for_printing.where(uuid: ids_for_print)
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

  def find_asset_groups(asset_groups_or_uuids)
    asset_groups_or_uuids.uniq.map do |asset_group_or_uuid|
      find_instance_of_class_by_uuid(AssetGroup, asset_group_or_uuid)
    end
  end

  def build_asset_groups(asset_groups)
    asset_groups.uniq.map do |asset_group_or_uuid|
      find_instance_of_class_by_uuid(AssetGroup, asset_group_or_uuid, true)
    end
  end

  def is_new_record?(uuid)
    !!(instances_from_uuid[uuid]&.new_record?)
  end

  def find_instance_of_class_by_uuid(klass, instance_or_uuid_or_id, create = false)
    if TokenUtil.is_wildcard?(instance_or_uuid_or_id)
      uuid = uuid_for_wildcard(instance_or_uuid_or_id)

      # Do not try to find it if it is a new wildcard created
      found = find_instance_from_uuid(klass, uuid) unless create
      found = ((instances_from_uuid[uuid] ||= klass.new(uuid: uuid))) if !found && create
    elsif TokenUtil.is_uuid?(instance_or_uuid_or_id)
      found = find_instance_from_uuid(klass, instance_or_uuid_or_id)
      if !found && create
        found = ((instances_from_uuid[instance_or_uuid_or_id] ||= klass.new(uuid: instance_or_uuid_or_id)))
      end
    else
      found = instance_or_uuid_or_id
    end
    unless found
      _produce_error(["#{klass} identified by '#{instance_or_uuid_or_id}' should be declared before using it"])
    end
    found
  end

  def uuid_for_wildcard(wildcard)
    wildcards[wildcard] ||= SecureRandom.uuid
  end

  def wildcard_for_uuid(uuid)
    wildcards.key(uuid)
  end

  def find_instance_from_uuid(klass, uuid)
    found = klass.find_by(uuid: uuid) unless is_new_record?(uuid)
    return found if found

    instances_from_uuid[uuid]
  end

  def validate_instances(instances)
    if instances.kind_of?(Array)
      instances.each { |a| raise StandardError, a if a.nil? }
    else
      raise StandardError, a if instances.nil?
    end
    instances
  end

  def set_errors(errors)
    errors_added.concat(errors)
    self
  end

  def create_assets(assets)
    assets_to_create << validate_instances(build_assets(assets))
    self
  end

  def create_asset_groups(asset_groups)
    asset_groups_to_create << validate_instances(build_asset_groups(asset_groups))
    self
  end

  def delete_asset_groups(asset_groups)
    asset_groups_to_destroy << validate_instances(find_asset_groups(asset_groups))
    self
  end

  def delete_assets(assets)
    assets_to_destroy << validate_instances(find_assets(assets))
    self
  end

  def add_assets(list)
    list.each do |elem|
      if (elem.length > 0) && elem[1].kind_of?(Array)
        asset_group = elem[0].nil? ? nil : validate_instances(find_asset_group(elem[0]))
        asset_ids = elem[1]
      else
        asset_group = nil
        asset_ids = elem
      end
      assets = validate_instances(find_assets(asset_ids))
      assets_to_add << assets.map { |asset| { asset_group: asset_group, asset: asset } }
    end
    self
  end

  def remove_assets(list)
    list.each do |elem|
      if (elem.length > 0) && elem[1].kind_of?(Array)
        asset_group = elem[0].nil? ? nil : validate_instances(find_asset_group(elem[0]))
        asset_ids = elem[1]
      else
        asset_group = nil
        asset_ids = elem
      end
      assets = validate_instances(find_assets(asset_ids))
      assets_to_remove << assets.map { |asset| { asset_group: asset_group, asset: asset } }
    end
    self
  end

  private

  def _handle_errors(step)
    step.set_errors(errors_added)
    _produce_error(errors_added) if errors_added.length > 0
  end

  def _produce_error(errors_added)
    raise StandardError.new(message: errors_added.join("\n"))
  end

  def _set_remote_facts(facts)
    Fact.where(id: facts.map(&:id).uniq.compact).update_all(is_remote?: true)
  end

  def _add_assets(step, asset_group_assets, with_operations = true)
    modified_list =
      asset_group_assets.map do |o|
        # If is nil, it will use the asset group from the step
        o[:asset_group] = o[:asset_group] || step.asset_group
        o
      end
    _instance_builder_for_import(AssetGroupsAsset, modified_list) do |instances|
      _asset_group_operations('addAssets', step, instances) if with_operations
    end
  end

  def _remove_assets(step, assets_to_remove, with_operations = true)
    modified_list =
      assets_to_remove.map do |obj|
        AssetGroupsAsset.where(asset_group: obj[:asset_group] || step.asset_group, asset: obj[:asset])
      end
    _instances_deletion(AssetGroupsAsset, modified_list) do |asset_group_assets|
      _asset_group_operations('removeAssets', step, asset_group_assets) if with_operations
    end
  end

  def _create_assets(step, assets, with_operations = true)
    return unless assets

    count = Asset.count + 1
    assets =
      assets.each_with_index.map do |asset, barcode_index|
        _build_barcode(asset, count + barcode_index)
        asset
      end
    _instance_builder_for_import(Asset, assets) do |_instances|
      _asset_operations('createAssets', step, assets) if with_operations
    end
  end

  ## TODO:
  # Possibly it could be moved to Asset before_save callback
  #
  def _build_barcode(asset, i)
    barcode_type = values_for_predicate(asset, 'barcodeType').first

    unless barcode_type == 'NoBarcode'
      barcode = values_for_predicate(asset, 'barcode').first
      if barcode
        asset.barcode = barcode
      else
        asset.build_barcode(i)
      end
    end
  end

  def _detach_assets(step, assets, with_operations = true)
    operations = _asset_operations('deleteAssets', step, assets) if with_operations
    _instances_deletion(Fact, assets.map(&:facts).flatten.compact)
    _instances_deletion(AssetGroupsAsset, assets.map(&:asset_groups_assets).flatten.compact)
    operations
  end

  def _create_asset_groups(step, asset_groups, with_operations = true)
    return unless asset_groups

    asset_groups.each do |asset_group|
      asset_group.update(
        name: TokenUtil.to_asset_group_name(wildcard_for_uuid(asset_group.uuid)),
        activity_owner: step.activity
      )
      asset_group.save
    end
    _asset_group_building_operations('createAssetGroups', step, asset_groups) if with_operations
  end

  def _detach_asset_groups(step, asset_groups, with_operations = true)
    operations = _asset_group_building_operations('deleteAssetGroups', step, asset_groups) if with_operations
    instances = asset_groups.flatten
    ids_to_remove = instances.filter_map(&:id).uniq

    AssetGroup.where(id: ids_to_remove).update_all(activity_owner_id: nil) if ids_to_remove && !ids_to_remove.empty?
    operations
  end

  def _create_facts(step, params_for_facts, with_operations = true)
    _instance_builder_for_import(Fact, params_for_facts) do |facts|
      _fact_operations('addFacts', step, facts) if with_operations
    end
  end

  def _remove_facts(step, facts_to_remove, with_operations = true)
    ids = []
    modified_list =
      facts_to_remove
        .reduce([]) do |memo, data|
          if data[:id]
            ids.push(data[:id])
          elsif data[:object].kind_of? String
            elems = Fact.where(asset: data[:asset], predicate: data[:predicate], object: data[:object])
          else
            elems = Fact.where(asset: data[:asset], predicate: data[:predicate], object_asset: data[:object_asset])
          end
          memo.concat(elems) if elems
          memo
        end
        .concat(Fact.where(id: ids))

    _instances_deletion(Fact, modified_list) { _fact_operations('removeFacts', step, modified_list) if with_operations }
  end

  def _asset_group_building_operations(action_type, step, asset_groups)
    asset_groups.map { |asset_group| Operation.new(action_type: action_type, step: step, object: asset_group.uuid) }
  end

  def _asset_group_operations(action_type, step, asset_group_assets)
    asset_group_assets.map do |asset_group_asset, _index|
      Operation.new(
        action_type: action_type,
        step: step,
        asset: asset_group_asset.asset,
        object: asset_group_asset.asset_group.uuid
      )
    end
  end

  def _asset_operations(action_type, step, assets)
    assets.map do |asset, _index|
      # refer = (action_type == 'deleteAsset' ? nil : asset)
      Operation.new(action_type: action_type, step: step, object: asset.uuid)
    end
  end

  def listening_to_predicate?(predicate)
    predicate == 'parent'
  end

  def _fact_operations(action_type, step, facts)
    modified_assets = []
    operations =
      facts.map do |fact|
        modified_assets.push(fact.object_asset) if listening_to_predicate?(fact.predicate)
        Operation.new(
          action_type: action_type,
          step: step,
          asset: fact.asset,
          predicate: fact.predicate,
          object: fact.object,
          object_asset: fact.object_asset
        )
      end

    modified_assets.flatten.compact.uniq.each(&:touch)
    operations
  end

  def any_values_are_new_records(hash)
    hash.values.any? { |value| value.try(:new_record?) }
  end

  def _instance_builder_for_import(klass, params_list)
    instances =
      params_list.filter_map do |params_for_instance|
        if params_for_instance.kind_of?(klass)
          params_for_instance if params_for_instance.new_record?
        elsif any_values_are_new_records(params_for_instance) || !klass.exists?(params_for_instance)
          klass.new(params_for_instance)
        end
      end.uniq
    instances.each do |instance|
      # Runs the callbacks (See https://github.com/zdennis/activerecord-import#callbacks)
      instance.run_callbacks(:save) { false }
      instance.run_callbacks(:create) { false }
    end
    if instances.present?
      klass.import(instances)

      # import does not return the ids for the instances, so we need to reload
      # again. Uuid is the only identificable attribute set
      klass.synchronize(instances, [:uuid]) if klass == Asset
      yield instances
    end
  end

  def _instances_deletion(klass, instances, &block)
    operations = block ? yield(instances) : instances
    instances = instances.flatten
    ids_to_remove = instances.filter_map(&:id).uniq

    klass.where(id: ids_to_remove).delete_all if ids_to_remove && !ids_to_remove.empty?
    operations
  end
end
