class BackgroundSteps::UpdateSequencescape < BackgroundSteps::BackgroundStep
  attr_accessor :printer_config

  def assets_compatible_with_step_type
    asset_group.assets.with_fact('pushTo', 'Sequencescape').count > 0
  end

  def execute_actions
    update_attributes!({
      :state => 'running',
      :asset_group => AssetGroup.create!(:assets => asset_group.assets.with_fact('pushTo', 'Sequencescape'))
    })
    background_job(printer_config, user)
  end


  def background_job(printer_config=nil, user=nil)
    ActiveRecord::Base.transaction do
      if assets_compatible_with_step_type
        asset_group.assets.each do |asset|
          asset.update_sequencescape(printer_config, user)
          #removed_facts = asset.facts.select{|f| f.predicate == 'pushTo' && f.object == 'Sequencescape'}
          #asset.remove_operations(removed_facts, self)
          #removed_facts.select{|f| f.predicate == 'pushTo' && f.object == 'Sequencescape'}.each do |f|
          #  f.destroy
          #end
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
