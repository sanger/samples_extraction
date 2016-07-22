class ActivityType < ActiveRecord::Base
  has_many :activities
  has_many :kit_types
  has_many :activity_type_step_types
  has_many :step_types, :through => :activity_type_step_types
  has_and_belongs_to_many :instruments

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
end
