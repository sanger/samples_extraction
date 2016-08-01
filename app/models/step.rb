class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group
  belongs_to :user
  has_many :uploads
  has_many :operations

  after_create :execute_actions, :unless => :in_progress?

  before_save :assets_compatible_with_step_type, :unless => :in_progress?

  class RelationCardinality < StandardError
  end

  class RelationSubject < StandardError
  end

  class UnknownConditionGroup < StandardError
  end

  scope :for_assets, ->(assets) { joins(:asset_group => :assets).where(:asset_group => {
    :asset_groups_assets=> {:asset_id => assets }
    }) }

  def assets_compatible_with_step_type
    throw :abort unless step_type.compatible_with?(asset_group.assets)
  end

  # Identifies which asset acting as subject is compatible with which rule.
  def classify_assets
    perform_list = []
    step_type.actions.includes([:subject_condition_group, :object_condition_group]).each do |r|
      if r.subject_condition_group.nil?
        raise RelationSubject, 'A subject condition group needs to be specified to apply the rule'
      end
      if (r.object_condition_group)
        unless [r.subject_condition_group, r.object_condition_group].any?{|c| c.cardinality == 1}
          # Because a condition group can refer to an unknown number of assets,
          # when a rule relates 2 condition groups (?p :transfers ?q) we cannot
          # know how to connect their assets between each other unless at least
          # one of the condition groups has maxCardinality set to 1
          msg = ['In a relation between condition groups, one of them needs to have ',
                'maxCardinality set to 1 to be able to infer how to connect its assets'].join('')
          #raise RelationCardinality, msg
        end
      end
      # If this condition group is referring to an element not matched (like
      # a new created asset, for example) I cannot classify my assets with it
      if (!step_type.condition_groups.include?(r.subject_condition_group))
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

  def unselect_assets_from_antecedents
    asset_group.unselect_assets_with_conditions(step_type.condition_groups)
    if activity
      activity.asset_group.unselect_assets_with_conditions(step_type.condition_groups)
    end
  end

  def unselect_assets_from_consequents
    asset_group.unselect_assets_with_conditions(step_type.action_subject_condition_groups)
    asset_group.unselect_assets_with_conditions(step_type.action_object_condition_groups)
    if activity
      activity.asset_group.unselect_assets_with_conditions(step_type.action_subject_condition_groups)
      activity.asset_group.unselect_assets_with_conditions(step_type.action_object_condition_groups)
    end
  end

  def execute_actions
    ActiveRecord::Base.transaction do |t|
      created_assets = {}
      list_to_destroy = []
      classify_assets.each do |asset, r|
        r.execute(self, asset_group, asset, created_assets, list_to_destroy)
      end

      unselect_assets_from_antecedents

      Fact.where(:id => list_to_destroy.flatten.compact.pluck(:id)).delete_all

      unselect_assets_from_consequents
    end
  end

  def progress_with(assets)
    ActiveRecord::Base.transaction do |t|
      update_attributes(:in_progress? => true)

      asset_group.assets << assets

      created_assets = {}
      classify_assets.each do |asset, r|
        r.execute(self, asset_group, asset, created_assets, nil)
      end
    end

    #activity.asset_group.update_attributes(:assets => activity.asset_group.assets - assets)
  end

  def finish_with(assets)
    ActiveRecord::Base.transaction do |t|
      unselect_assets_from_antecedents
      Fact.where(:to_remove_by => self.id).delete_all
      Fact.where(:to_add_by => self.id).update_all(:to_add_by => nil)
      unselect_assets_from_consequents
      update_attributes(:in_progress? => false)
    end
  end

end
