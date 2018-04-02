class ActivityChannel < ApplicationCable::Channel

  def subscribed
    stream_from "activity_#{params[:activity_id]}"
  end
end
