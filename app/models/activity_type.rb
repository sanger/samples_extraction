class ActivityType < ActiveRecord::Base
  has_many :activities
  has_many :kit_types
  has_many :activity_type_step_types
  has_many :step_types, :through => :activity_type_step_types
  has_and_belongs_to_many :instruments

  has_many   :supercedes,    :class_name => 'ActivityType', :foreign_key => :superceded_by_id
  belongs_to :superceded_by, :class_name => 'ActivityType', :foreign_key => :superceded_by_id
  #has_many :valid_activity_type, ->() { left_outer_joins(:superceded_by).visible }
  scope :visible, -> { where( :superceded_by_id => nil ) }

  def deprecate_with(activity_type)
    supercedes.concat(self).flatten.each do |a|
      a.update_attributes!(:superceded_by_id => activity_type.id)
      a.kit_types.each do |kit_type|
        kit_type.update_attributes!(:activity_type_id => activity_type.id)
      end
    end
  end
end
