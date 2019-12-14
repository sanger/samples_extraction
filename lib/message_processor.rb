class MessageProcessor
  include ActiveModel::Validations

  attr_reader :channel

  def initialize(params)
    @channel = params[:channel]
  end

  def interested_in?(message)
    false
  end

  def process(message)
    false
  end
end
