module Deprecatable
  def self.included(base)
    base.instance_eval do
      has_many   :supercedes,    :class_name => 'ActivityType', :foreign_key => :superceded_by_id
      belongs_to :superceded_by, :class_name => 'ActivityType', :foreign_key => :superceded_by_id

      scope :visible, -> { where( :superceded_by_id => nil ) }
      scope :not_deprecated, -> { where( :superceded_by_id => nil ) }

    end
  end

  def after_deprecate
  end

  def deprecate_with(activity_type)
    [supercedes, self.class.where(:name => name)].flatten.each do |a|
      if a.id != activity_type.id
        a.update_attributes!(:superceded_by_id => activity_type.id)
      end
    end
    after_deprecate
  end
end
