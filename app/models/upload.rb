class Upload < ApplicationRecord
  belongs_to :step

  def has_step?
    !step.nil?
  end
end
