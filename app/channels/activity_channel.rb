class ActivityChannel < ApplicationCable::Channel

  def self.connection_for_redis
    ActionCable.server.pubsub.redis_connection_for_subscriptions
  end

  def connection_for_redis
    self.class.connection_for_redis
  end

  def self.subscribed_ids
    value = connection_for_redis.get('SUBSCRIBED_IDS')
    return [] unless value
    JSON.parse(value)
  end

  def subscribed_ids
    self.class.subscribed_ids
  end

  def stream_id
    "activity_#{params[:activity_id]}"
  end

  def subscribed
    previous_value = subscribed_ids || []
    connection_for_redis.set('SUBSCRIBED_IDS', previous_value.push(stream_id)) unless previous_value.include?(stream_id)

    stream_from stream_id
  end

  def unsubscribed
    previous_value = subscribed_ids
    connection_for_redis.set('SUBSCRIBED_IDS', previous_value.reject{|v| v== stream_id })
  end
end
