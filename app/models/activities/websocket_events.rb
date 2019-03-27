module Activities::WebsocketEvents
  def self.included(klass)
    klass.instance_eval do
      after_commit :wss_event
    end
  end

  def running_inside_transaction?
    ActiveRecord::Base.connection.open_transactions == 0
  end

  def send_wss_event(data)
    ActionCable.server.broadcast(stream_id, data)
  end

  def stream_id
    "activity_#{id}"
  end

  def websockets_attributes(attrs)
    attrs.keys.reduce({shownComponents: {}}) do |memo, key|
      memo[key] = attrs[key].call unless (ActivityChannel.activity_attributes(id)[key.to_s] == false)
      memo
    end
  end

  def initial_websockets_attributes(attrs)
    attrs.keys.reduce({}) do |memo, key|
      memo[key] = attrs[key].call
      memo
    end
  end

  def wss_event
    if Rails.configuration.redis_enabled && ActivityChannel.subscribed_ids.include?(stream_id)
      send_wss_event(websockets_attributes(json_attributes))
    end
  end

end
