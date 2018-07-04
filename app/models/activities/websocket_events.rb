module Activities::WebsocketEvents
  def self.included(klass)
    klass.instance_eval do
      after_commit :wss_event
    end
  end

  def running_inside_transaction?
    ActiveRecord::Base.connection.open_transactions == 0
  end

  def send_wss_event
    ActionCable.server.broadcast(stream_id, json_attributes) 
  end

  def stream_id
    "activity_#{id}"
  end

  def wss_event
    if ActivityChannel.subscribed_ids.include?(stream_id)
      send_wss_event
    end
  end

end