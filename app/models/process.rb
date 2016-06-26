class Process < ActiveRecord::Base
  belongs_to :process_type
  has_many :steps

  def steps_finished(assets)
  end

  def steps_active(assets)
  end
end
