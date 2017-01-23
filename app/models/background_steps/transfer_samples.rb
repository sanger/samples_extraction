class BackgroundSteps::TransferSamples < Step

  def assets_compatible_with_step_type
    asset_group.assets.with_predicate('transfer').count > 0
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

    asset_group.assets.each do |asset|
      asset.add_facts([Fact.new(:predicate => 'is', :object => 'Used')])
      asset.facts.with_predicate('transfer').each do |fact|
        modified_asset = fact.object_asset
        added_facts = asset.facts.with_predicate('sanger_sample_id').map do |aliquot_fact|
          [Fact.new(:predicate => 'sanger_sample_id', :object => aliquot_fact.object),
          Fact.new(:predicate => 'sample_id', :object => aliquot_fact.object)]
        end.flatten

        modified_asset.add_facts(added_facts)
        modified_asset.add_operations(added_facts, self)
      end
    end
    asset_group.touch
    update_attributes!(:state => 'complete')
  end

  handle_asynchronously :background_job

end