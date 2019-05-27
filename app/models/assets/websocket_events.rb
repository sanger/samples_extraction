module Assets::WebsocketEvents
  def self.included(klass)
    klass.instance_eval do
      after_touch :touch_asset_groups
    end
  end

  def touch_asset_groups
    asset_groups.each(&:touch)
  end

end