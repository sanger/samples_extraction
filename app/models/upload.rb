class Upload < ApplicationRecord
  belongs_to :step
  belongs_to :activity

  def has_step?
    !step.nil?
  end
end
