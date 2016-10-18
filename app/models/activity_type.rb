class ActivityType < ActiveRecord::Base
  has_many :activities
  has_many :kit_types
  has_many :condition_groups, :through => :step_types
  has_many :activity_type_step_types
  has_many :step_types, :through => :activity_type_step_types
  has_and_belongs_to_many :instruments

  has_many :conditions, :through => :condition_groups

  has_many :activity_type_compatibilities
  has_many :assets, :through => :activity_type_compatibilities

  include Deprecatable


  def after_deprecate
    self.reload
    main_instance = self.superceded_by
    main_instance.supercedes.each do |activity_type|
      activity_type.kit_types.each do |kit_type|
        kit_type.update_attributes!(:activity_type => main_instance)
      end
      activities.each do |activity|
        activity.update_attributes!(:activity_type => main_instance)
      end
    end
  end

  def compatible_with?(assets)
    condition_groups.any?{|c| c.compatible_with?(assets)}
  end
end
