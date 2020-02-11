class ActivityChannel < ApplicationCable::Channel
  include ChannelConcerns::MessagesProcessing
  include ChannelConcerns::StreamsManagement

  def stream_id
    "activity_#{params[:activity_id]}"
  end

  def subscribed
    add_stream_to_list(stream_id)

    create_message_processors!
    stream_from stream_id
  end

  def unsubscribed
    remove_stream_from_list(stream_id)

    stop_all_streams
  end

  def receive(message_from_frontend)
    process_message(message_from_frontend)
  end

  def redis
    self.class.redis
  end

  def self.redis
    ActionCable.server.pubsub.redis_connection_for_subscriptions
  end

end
