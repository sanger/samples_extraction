class Capacity < ActiveRecord::Base
  belongs_to :instrument
  belongs_to :process_type
end
