class ActivityChannel < ApplicationCable::Channel
  @@SUBSCRIBED = []

  def self.subscribed_ids
    @@SUBSCRIBED    
  end

  def stream_id
    "activity_#{params[:activity_id]}"
  end

  def subscribed
    @@SUBSCRIBED.push(stream_id)

    stream_from stream_id
  end

  def unsubscribed
    @@SUBSCRIBED -= [stream_id]
  end
end
