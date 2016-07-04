class Instrument < ActiveRecord::Base
  has_and_belongs_to_many :activity_types
  has_many :activities
end
