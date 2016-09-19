class LabelTemplate < ActiveRecord::Base
  validates_presence_of :name, :external_id
  validates_uniqueness_of :name, :external_id

  scope :for_type, ->(type) { where(:template_type => type)}
end
