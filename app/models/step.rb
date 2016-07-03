class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group

  after_create :execute_actions

  def classify_assets
    binding.pry
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
    created_assets = {}
    classify_assets.each do |asset, r|
      if r.condition_group.conditions.empty?
        asset = created_assets[r.condition_group.id]
      end
      if r.action_type == 'selectAsset'
        activity.asset_group.assets << asset
      end
      if r.action_type == 'createAsset'
        unless created_assets.keys.include?(r.condition_group.id)
          created_assets[r.condition_group.id] = Asset.create!
        end
        created_assets[r.condition_group.id].facts << Fact.create(:predicate => r.predicate, :object => r.object)
      end
      if r.action_type == 'addFacts'
        asset.facts << Fact.create(:predicate => r.predicate, :object => r.object)
      end
      if r.action_type == 'removeFacts'
        asset.facts.select{|f| f.predicate == r.predicate && f.object == r.object }.each(&:destroy)
      end
    end
  end
end
