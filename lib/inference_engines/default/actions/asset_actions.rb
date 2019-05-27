module InferenceEngines
  module Default
    module Actions
      module AssetActions
        def num_assets_for_condition_group(condition_group)
          return original_assets.count unless (condition_group.cardinality) && (condition_group.cardinality!=0)
          return [[original_assets.count, condition_group.cardinality].min, 1].max
        end

        def get_or_create_assets_for_condition_group(condition_group)
          unless created_assets[condition_group.id]
            # If the referred condition group does not exist it means
            # we have to create the new group
            num_assets_for_condition_group(condition_group).times.map do
              Asset.new
            end.tap do |assets|
              created_assets[condition_group.id] = assets
              asset_group.assets << assets
              AssetGroup.create(
                activity_owner: @step.activity,
                assets: assets,
                condition_group: condition_group)
            end

            @step.activity.touch if @step.activity
          end
          created_assets[condition_group.id]
        end

        def create_asset
          get_or_create_assets_for_condition_group(action.subject_condition_group).each_with_index do |created_asset, i|
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
            step.asset_group.touch
          end
        end

        def select_asset
          step.asset_group.add_assets(asset)
        end
      end
    end
  end
end
