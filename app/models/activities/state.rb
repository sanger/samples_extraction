module Activities::State
  def self.included(klass)
    klass.instance_eval do
      scope :in_progress, ->() { where('completed_at is null')}
      scope :finished, ->() { where('completed_at is not null')}
    end
  end

  def finish
    ActiveRecord::Base.transaction do
      update_attributes(:completed_at => DateTime.now)
      if work_order
        work_order.complete
      end
    end
  end

  def finished?
    !completed_at.nil?
  end  

  def running?
    (steps.active.count > 0)
  end

  def editing!
    update(state: 'editing')
  end

  def in_progress!
    update(state: 'in_progress')
  end

  def editing?
    state == 'editing'
  end

end