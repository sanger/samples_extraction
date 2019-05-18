module Steps::Deprecatable
  def self.included(klass)
    klass.instance_eval do
      scope :deprecatable, ->() { cancelled.or(pending).or(stopped) }
      before_update :check_deprecatables
    end
  end

  def check_deprecatables
    if ((state == 'running') && (state_was == nil))
      deprecate_unused_previous_steps!
    end
  end


  def deprecate_unused_previous_steps!
    if activity
      activity.steps.deprecatable.older_than(self).each do |s|
        s.deprecate_with(self)
      end
    end
  end

  def after_deprecate
    update_attributes(:state => 'deprecated', :activity => nil)
  end

end
