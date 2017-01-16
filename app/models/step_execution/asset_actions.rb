module StepExecution::AssetActions
  def create_asset
    unless created_assets[action.subject_condition_group.id]
      num_create = original_assets.count
      if (action.subject_condition_group.cardinality) && (action.subject_condition_group.cardinality!=0)
        num_create = [original_assets.count, action.subject_condition_group.cardinality].min
      end
      @changed_assets= num_create.times.map{|i| Asset.create!}

      # Each fact of a createAsset action is considered an action by
      # itself, because of that, before creating the assetswe check
      # if they were already created by a previous action
      created_assets[action.subject_condition_group.id] = changed_assets
      asset_group.add_assets(changed_assets)
    end

    # Is the following line needed??
    @changed_assets= created_assets[action.subject_condition_group.id]

    #debugger
    created_assets[action.subject_condition_group.id].each_with_index do |created_asset, i|
      if (created_asset.has_literal?('barcodeType', 'NoBarcode'))
        created_asset.update_attributes(:barcode => nil)
      else
        created_asset.generate_barcode(i)
      end
      @changed_facts = generate_facts.map(&:dup)
      created_asset.add_facts(changed_facts, i) do |fact|
        create_operation(created_asset, fact)
      end
    end
  end

  def save_created_assets
    list_of_assets = created_assets.values.uniq
    if list_of_assets.length > 0
      created_asset_group = AssetGroup.create
      created_asset_group.add_assets(list_of_assets)
      step.activity.asset_group.add_assets(list_of_assets) if step.activity
      step.update_attributes(:created_asset_group => created_asset_group)
    end
  end

  def select_asset
    step.asset_group.add_assets(asset)
  end

end
