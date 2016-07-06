class Operation < ApplicationRecord
  belongs_to :step
  belongs_to :asset
  belongs_to :action
  belongs_to :activity
end
