module Steps::Compatible
  def self.included(klass)
    klass.instance_eval do
      #before_create :assets_compatible_with_step_type, :unless => [:in_progress?]
    end
  end

  def assets_compatible_with_step_type
    return true if asset_group.nil?
    checked_condition_groups=[], @wildcard_values = {}
    compatible = step_type.compatible_with?(asset_group_assets, nil, checked_condition_groups, wildcard_values)
    raise StandardError unless compatible
  end

  def asset_group_assets
    asset_group ? asset_group.assets : []
  end

end
