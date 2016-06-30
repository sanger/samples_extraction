class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group

  after_create :execute_actions

  def classify_assets
    perform_list = []
    step_type.actions.each do |r|
      asset_group.assets.each do |asset|
        if r.condition_group.compatible_with?(asset)
          perform_list.push([asset, r])
        end
      end
    end
    perform_list
  end


  def execute_actions
    classify_assets.each do |asset, r|
      if r.action_type == 'addFacts'
        asset.facts << Fact.create(:predicate => r.predicate, :object => r.object)
      else
        asset.facts.delete(asset.facts.select{|f| f.predicate == r.predicate && f.object == r.object })
      end
    end
  end
end
