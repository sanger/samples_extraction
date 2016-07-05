class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group
  has_many :uploads
  after_create :execute_actions

  def classify_assets
    perform_list = []
    step_type.actions.each do |r|
      if r.subject_condition_group.cardinality == 1
        perform_list.push([nil, r])
      else
        asset_group.assets.each do |asset|
          if r.subject_condition_group.compatible_with?(asset)
            perform_list.push([asset, r])
          end
        end
      end
    end
    perform_list.sort do |a,b|
      if a[1].action_type=='createAsset'
        -1
      elsif b[1].action_type=='createAsset'
        1
      else
        a[1].action_type <=> b[1].action_type
      end
    end
  end

  def build_fact(r, created_assets)
    if r.object_condition_group.nil?
      fact = Fact.create(:predicate => r.predicate, :object => r.object)
    else
      fact = Fact.create(
        :predicate => r.predicate,
        :object => created_assets[r.object_condition_group.id].uuid)
    end
  end

  def execute_actions
    created_assets = {}
    classify_assets.each do |asset, r|
      if r.subject_condition_group.conditions.empty?
        asset = created_assets[r.subject_condition_group.id]
      end
      if r.action_type == 'selectAsset'
        activity.asset_group.assets << asset
      end
      if r.action_type == 'createAsset'

        asset = Asset.create!
        created_assets[r.subject_condition_group.id] = asset
        activity.asset_group.assets << asset

        created_assets[r.subject_condition_group.id].facts << build_fact(r, created_assets)
      end
      if r.action_type == 'addFacts'
        asset.facts << build_fact(r, created_assets)
      end
      if r.action_type == 'removeFacts'
        asset.facts.select{|f| f.predicate == r.predicate && r.object.nil? ||
          (f.object == r.object) }.each(&:destroy)
      end
    end
  end

end
