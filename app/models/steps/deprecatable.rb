module Steps::Deprecatable
  def self.included(klass)
    klass.instance_eval do
      scope :deprecatable, ->() { cancelled.or(failed).or(stopped) }
    end
  end

  def following_step_ids
    obj=self
    list=[]
    loop do
      id = obj.next_step_id
      return list if id.nil?
      return list if list.include?(id)
      list.push(id)
      obj = next_step
    end
  end

  def deprecate_unused_previous_steps!
    if activity
      activity.steps.deprecatable.older_than(self).where.not(id: following_step_ids).each do |s|
        s.deprecate_with(self)
      end
    end
  end

  def after_deprecate
    deprecate!
  end

  def remove_from_activity
    self.activity = nil
    save!
  end

end
