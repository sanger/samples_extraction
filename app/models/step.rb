class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group
  belongs_to :user
  has_many :uploads
  has_many :operations

  after_create :execute_actions

  scope :for_assets, ->(assets) { joins(:asset_group => :assets).where(:asset_group => {
    :asset_groups_assets=> {:asset_id => assets }
    }) }

  def classify_assets
    perform_list = []
    step_type.actions.includes([:subject_condition_group, :object_condition_group]).each do |r|
      if r.subject_condition_group.cardinality == 1
        perform_list.push([nil, r])
      else
        asset_group.assets.includes(:facts).each do |asset|
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

  def unselect_groups
    step_type.condition_groups.each do |condition_group|
      unless condition_group.keep_selected
        unselect_assets = activity.asset_group.assets.includes(:facts).select{|asset| condition_group.compatible_with?(asset)}
        activity.asset_group.assets.delete(unselect_assets) if unselect_assets
      end
    end
  end

  def execute_actions
    ActiveRecord::Base.transaction do |t|
      created_assets = {}
      list_to_destroy = []
      classify_assets.each do |asset, r|
        r.execute(self, asset, created_assets, list_to_destroy)
      end
      unselect_groups
      Fact.where(:id => list_to_destroy.flatten.compact.pluck(:id)).delete_all
    end
  end

end
