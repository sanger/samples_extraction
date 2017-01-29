class BackgroundSteps::TransferSamples < Step

  def assets_compatible_with_step_type
    #asset_group.assets.with_predicate('transfer').count > 0
    Asset.with_predicate('transfer').count > 0
  end

  def execute_actions
    update_attributes!({
      :state => 'running',
      :step_type => StepType.find_or_create_by(:name => 'TransferSamples'),
      :asset_group => AssetGroup.create!(:assets => asset_group.assets.with_predicate('transfer'))
    })
    background_job
  end

  def background_job
    return unless assets_compatible_with_step_type

    Asset.with_predicate('transfer').each do |asset|

    #asset_group.assets.each do |asset|
      asset.add_facts([Fact.new(:predicate => 'is', :object => 'Used')])
      asset.facts.with_predicate('transfer').each do |fact|
        modified_asset = fact.object_asset
        added_facts = asset.facts.with_predicate('sanger_sample_id').map do |aliquot_fact|
          [Fact.new(:predicate => 'sanger_sample_id', :object => aliquot_fact.object),
          Fact.new(:predicate => 'sample_id', :object => aliquot_fact.object)
        ]
        end.flatten
        added_facts.concat(asset.facts.with_predicate('aliquotType').map do |aliquot_fact|
          [Fact.new(:predicate => 'aliquotType', :object => aliquot_fact.object)
        ]
        end.flatten)
        added_facts.push(Fact.new(:predicate => 'transferredFrom', :object_asset => asset))


        modified_asset.add_facts(added_facts)
        modified_asset.add_operations(added_facts, self)
      end
      #end
      asset.facts.with_predicate('parent').each do |f|
        f.object_asset.touch
      end
      asset.asset_groups.each(&:touch)
    end
    #asset_group.touch

    update_attributes!(:state => 'complete')
  ensure
    update_attributes!(:state => 'error') unless state == 'complete'
    asset_group.touch    
  end

  handle_asynchronously :background_job

end