module Steps::Deprecatable
  def self.included(klass)
    klass.instance_eval do
      after_create :deprecate_cancelled_steps
    end
  end  

  def deprecate_cancelled_steps
    if activity
      activity.steps.cancelled.each do |s|
        s.deprecate_with(self)
      end
    end
  end

  def after_deprecate
    update_attributes(:state => 'deprecated', :activity => nil)
  end

end