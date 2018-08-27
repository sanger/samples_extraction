module InferenceEngines
  module Default
    module Actions
      module AssetActions
        def create_asset
          unless created_assets[action.subject_condition_group.id]
            num_create = original_assets.count
            if (action.subject_condition_group.cardinality) && (action.subject_condition_group.cardinality!=0)
              num_create = [[original_assets.count, action.subject_condition_group.cardinality].min, 1].max
            end
            @changed_assets= num_create.times.map{|i| Asset.create!}
            #unless action.subject_condition_group.name.nil?
              AssetGroup.create(
                :activity_owner => @step.activity,
                :assets => @changed_assets,
                :condition_group => action.subject_condition_group)
              @step.activity.touch if @step.activity
            #end

            # Each fact of a createAsset action is considered an action by
            # itself, because of that, before creating the assetswe check
            # if they were already created by a previous action
            created_assets[action.subject_condition_group.id] = changed_assets
            asset_group.add_assets(changed_assets)
          end

          # Is the following line needed??
          @changed_assets= created_assets[action.subject_condition_group.id]

          created_assets[action.subject_condition_group.id].each_with_index do |created_asset, i|
            @changed_facts = generate_facts.map(&:dup)
            @changed_facts.each do |fact|
              updates.add(created_asset, fact.predicate, fact.object_value || fact.object)
            end
          end
        end

        def save_created_assets
          list_of_assets = created_assets.values.flatten.uniq

          list_of_assets.each_with_index do |asset, i|
            if (asset.has_literal?('barcodeType', 'NoBarcode'))
              asset.update_attributes(:barcode => nil)
            else
              asset.generate_barcode(i)
            end
          end

          if list_of_assets.length > 0
            created_asset_group = AssetGroup.create
            created_asset_group.add_assets(list_of_assets)
            step.update_attributes(:created_asset_group => created_asset_group)
          end
        end

        def select_asset
          step.asset_group.add_assets(asset)
        end
      end
    end
  end
end
