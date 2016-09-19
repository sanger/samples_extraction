class Step < ActiveRecord::Base
  belongs_to :activity
  belongs_to :step_type
  belongs_to :asset_group
  belongs_to :user
  has_many :uploads
  has_many :operations

  belongs_to :created_asset_group, :class_name => 'AssetGroup', :foreign_key => 'created_asset_group_id'

  scope :in_progress, ->() { where(:in_progress? => true)}

  after_create :execute_actions, :unless => :in_progress?

  before_create :assets_compatible_with_step_type, :unless => :in_progress?

  class RelationCardinality < StandardError
  end

  class RelationSubject < StandardError
  end

  class UnknownConditionGroup < StandardError
  end

  scope :for_assets, ->(assets) { joins(:asset_group => :assets).where(:asset_groups_assets =>  {:asset_id => assets })}


  scope :for_step_type, ->(step_type) { where(:step_type => step_type)}

  def assets_compatible_with_step_type
    raise StandardError unless step_type.compatible_with?(asset_group.assets) || (asset_group.assets.count == 0)
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

  def save_created_assets(created_assets)
    list_of_assets = created_assets.values.uniq
    if list_of_assets.length > 0
      created_asset_group = AssetGroup.create
      created_asset_group.assets << list_of_assets
      activity.asset_group.assets << list_of_assets if activity
      update_attributes(:created_asset_group => created_asset_group)
    end
  end

  def execute_actions
    return progress_with(asset_group.assets) if in_progress?
    original_assets = AssetGroup.create!
    original_assets.assets << activity.asset_group.assets if activity

    ActiveRecord::Base.transaction do |t|
      created_assets = {}
      list_to_destroy = []
      classify_assets.each do |asset, r|
        r.execute(self, asset_group, asset, created_assets, list_to_destroy)
      end

      save_created_assets(created_assets)

      unselect_assets_from_antecedents

      Fact.where(:id => list_to_destroy.flatten.compact.map(&:id)).delete_all

      update_assets_started if activity

      unselect_assets_from_consequents

      update_service
    end
    update_attributes(:asset_group => original_assets) if activity
  end

  def update_assets_started
    activity.asset_group.assets.not_started.each do |asset|
      asset.facts << Fact.create(:predicate => 'is', :object => 'Started')
      asset.facts.where(:predicate => 'is', :object => 'NotStarted').destroy
    end
  end

  def progress_with(step_params)
    ActiveRecord::Base.transaction do |t|
      assets = step_params[:assets]
      update_attributes(:in_progress? => true)

      asset_group.assets << assets

      created_assets = {}
      classify_assets.each do |asset, r|
        r.execute(self, asset_group, asset, created_assets, nil)
      end
      save_created_assets(created_assets)

      asset_group.update_attributes(:assets => [])
      finish if step_params[:state]=='done'
    end
  end

  def finish
    ActiveRecord::Base.transaction do |t|
      unselect_assets_from_antecedents
      Fact.where(:to_remove_by => self.id).delete_all
      Fact.where(:to_add_by => self.id).update_all(:to_add_by => nil)
      unselect_assets_from_consequents

      update_service

      update_attributes(:in_progress? => false)
    end
  end

  def service_update_hash(asset, depth=0)
    raise 'Too many recursion levels' if (depth > 5)
    [asset.facts.literals.map do |f|
      {
        predicate_to_property(f.predicate) => f.object
      }
    end,
    asset.facts.not_literals.map do |f|
      {
        predicate_to_property(f.predicate) => service_update_hash(f.object_asset_id, depth+1)
      }
    end].flatten.merge
  end

  def update_service
    #ActiveRecord::Base.transaction do |t|
    #  activity.asset_group.assets.marked_to_update.with_update_transformation.map do |a|
    #    service_update_hash(a)
    #  end
    #end
  end
end
