class BackgroundSteps::TubeAndWellsMatching < Step
  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('contains')
  end

  def execute_actions
    update_attributes!({
      :state => 'running',
      :step_type => StepType.find_or_create_by(:name => 'TubeAndWellsMatching'),
      :asset_group => AssetGroup.create!(:assets => asset_group.assets)
    })
    background_job(printer_config, user)
  end

  def object_from_asset(asset)
    asset.facts.with_predicate('contains').reduce({}) do |memo, fact|
      asset = fact.object_asset
      location = asset.facts.with_predicate('location').first.object
      memo[location] = [] unless memo[location]
      memo[location].push(asset)
      memo
    end    
  end

  def process_asset(asset)
    object_from_asset(asset).each do |location, assets|
      if assets.length == 2
        asset1, asset2 = assets
        asset1.add_facts(asset2.facts.map(&:dup))
        asset2.add_facts(asset1.facts.map(&:dup))
      end
    end
  end

  def assets_with_wells_and_tubes(assets)
    assets.select do |asset|
      object_from_asset(asset).any? do |location, assets|
        assets.uniq.length == 2
      end
    end
  end

  def background_job(printer_config=nil, user=nil)
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type.count > 0
        assets_compatible_with_step_type.each do |asset|
          asset.facts.with_predicate('contains').reduce({}) do |memo, fact|
            asset = fact.object_asset
            location = asset.facts.with_predicate('location').first
            memo[location] = [] unless memo[location]
            memo[location].push(asset)
          end.each do |location, assets|
            if assets.length == 2
              asset1, asset2 = assets
              add_facts(asset1, asset2.facts)
              add_facts(asset2, asset1.facts)
            end
          end
        end
      end
    end
    update_attributes!(:state => 'complete')
    asset_group.touch
  ensure
    update_attributes!(:state => 'error') unless state == 'complete'
    asset_group.touch
  end

  handle_asynchronously :background_job

end
