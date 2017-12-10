class WorkOrder < ApplicationRecord
  belongs_to :activity

  def self.build_from_params(work_order_params)
    ActiveRecord::Base.transaction do
      container_barcodes = []
      activity_type = ActivityType.find_by(name: work_order_params[:product_name])

      assets = work_order_params[:materials].map do |asset_params|
        asset = Asset.find_by(uuid: asset_params['_id'])
        if asset
          asset.update_attributes(facts: [])
        else
          asset = Asset.create!(uuid: asset_params['_id'])
        end
        selectable = asset
        asset_params.each_pair do |k, v|
          if (k == 'container')
            set_aker_container(asset, v, container_barcodes)
            selectable = asset.facts.with_predicate('parent').first.object_asset
          else
            asset.add_facts(Fact.create(predicate: k, object: v))
          end
        end
        asset.add_facts(Fact.create(predicate: 'aliquotType', object: 'DNA'))
        asset.add_facts(Fact.create(predicate: 'importedFrom', object: 'Aker'))
        selectable
      end

      asset_group = AssetGroup.create(assets: assets)

      activity = Activity.create(asset_group: asset_group, activity_type: activity_type, 
        instrument: Instrument.first, kit: Kit.first)

      WorkOrder.create!(work_order_id: work_order_params[:work_order_id], activity: activity)
    end    
  end

  def self.reset_aker_rack(rack)
    ['num_of_rows', 'num_of_cols', 'col_is_alpha', 'row_is_alpha', 'a', 'contains'].each do |pred|
      rack.facts.with_predicate(pred).each(&:destroy)
    end
  end

  def self.set_aker_container(asset, container_params, container_barcodes = [])
    barcode = container_params['barcode']
    parent = Asset.find_or_create_by(barcode: barcode)
    unless container_barcodes.include?(barcode)
      reset_aker_rack(parent)
      
      container_barcodes.push(barcode)
    end
    parent.add_facts(Fact.create(predicate: 'num_of_rows', object: container_params['num_of_rows']))
    parent.add_facts(Fact.create(predicate: 'num_of_cols', object: container_params['num_of_cols']))
    parent.add_facts(Fact.create(predicate: 'col_is_alpha', object: container_params['col_is_alpha']))
    parent.add_facts(Fact.create(predicate: 'row_is_alpha', object: container_params['row_is_alpha']))

    parent.add_facts(Fact.create(predicate: 'a', object: 'Plate'))
    parent.add_facts(Fact.create(predicate: 'contains', object_asset: asset))
    position = container_params['address'].gsub(/:/,'')
    asset.add_facts(Fact.create(predicate: 'parent', object_asset: parent))
    asset.add_facts(Fact.create(predicate: 'location', object: position))
  end


  def complete
    _finish_work("#{Rails.configuration.aker_work_order_completion_url}/#{work_order_id}/complete")
  end

  def cancel
    _finish_work("#{Rails.configuration.aker_work_order_completion_url}/#{work_order_id}/cancel")
  end

  def msg
    obj = {
      work_order: {
        work_order_id: work_order_id,
        comment: "Activity is in http://localhost:9200/activities/#{activity.id}"
      }
    }

    obj[:work_order][:updated_materials] = updated_materials_msg unless updated_materials_msg.empty?
    obj[:work_order][:new_materials] = new_materials_msg unless new_materials_msg.empty?
    obj[:work_order][:containers] = containers_msg unless containers_msg.empty?

    obj
  end

  def materials_with_fact(predicate, object)
    first_level_assets = activity.asset_group.assets.select{|a| a.has_literal?(predicate, object)}
    second_level_assets = activity.asset_group.assets.map do |asset|
      asset.facts.with_predicate('contains').map(&:object_asset).select{|a| a.has_literal?(predicate, object)}
    end.flatten.compact

    [first_level_assets, second_level_assets].flatten.compact
  end

  def valid_aker_property?(predicate)
    ["_id", "gender", "donor_id", "phenotype", "scientific_name", "is_tumour", 
      "supplier_name", "taxon_id", "tissue_type", "available"].include?(predicate)
  end

  def material_msg(material, include_container = false)
    msg = {}
    material.facts.each do |fact|
      if valid_aker_property?(fact.predicate)
        if (fact.predicate == '_id')
          msg[fact.predicate] = material.uuid
        elsif (fact.predicate == 'available')
          msg[fact.predicate] = (fact.object.to_i == 1)
        else
          msg[fact.predicate] = fact.object_asset ? fact.object_asset.uuid : fact.object
        end
      end
    end

    if (include_container)
      parent_fact = material.facts.with_predicate('parent').first
      if (parent_fact)
        parent = parent_fact.object_asset
        container = { barcode: parent.barcode }
        location_fact = material.facts.with_predicate('location').first
        if location_fact
          address = location_fact.object[0] + ":" + location_fact.object[1..-1]
          container[:address] = address
        end
        msg[:container] = container
      end
    end
    return nil if msg.empty?
    msg
  end

  def materials_msg(materials, include_container=false)
    materials.map{|material| material_msg(material, include_container)}
  end

  def updated_materials
    materials_with_fact('importedFrom', 'Aker')
  end

  def new_materials
    materials_with_fact('exportTo', 'Aker')
  end

  def new_materials_msg
    @_new_materials_msg ||= materials_msg(new_materials, true)    
  end

  def updated_materials_msg
    @_updated_materials_msg ||= materials_msg(updated_materials)
  end

  def containers_msg
    new_materials.map do |asset|
      asset.facts.with_predicate('parent').map(&:object_asset)
    end.flatten.compact.uniq.map do |container|
      cont_msg = {
        barcode: container.barcode
      }
      ['row_is_alpha','col_is_alpha','num_of_rows','num_of_cols'].reduce(cont_msg) do |memo, value|
        if container.facts.with_predicate(value).first
          memo[value] = container.facts.with_predicate(value).first.object
        end
        if (value == 'num_of_rows') || (value == 'num_of_cols')
          memo[value] = memo[value].to_i
        end
        if (value == 'row_is_alpha' && !memo[value])
          memo[value] = true
        end
        if (value == 'col_is_alpha' && !memo[value])
          memo[value] = false
        end        
        memo
      end
    end
  end

  private

  def _finish_work(url)
    RestClient.post url, msg.to_json, {content_type: :json, accept: :json}
  end
end