class MessageProcessor
  include ActiveModel::Validations

  attr_reader :channel

  delegate :current_user, to: :@channel

  def initialize(params)
    @channel = params[:channel]
  end

  def activity_id
    channel.params[:activity_id]
  end

  def interested_in?(message)
    false
  end

  def process(message)
    false
  end

end
