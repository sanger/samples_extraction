class ActivityTypeCompatibility < ApplicationRecord
  belongs_to :activity_type
  belongs_to :asset
end
