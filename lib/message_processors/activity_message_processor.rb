require 'message_processor'

module MessageProcessors
  class ActivityMessageProcessor < MessageProcessor
    delegate :redis, to: :channel

    def initialize(params)
      super(params)
    end

    def interested_in?(message)
      !!(message["activity"])
    end

    def process(message)
      _process_activity(params_for_activity(message))
    end

    def self.redis
      ActivityChannel.redis
    end

    def self.activity_attributes(id)
      begin
        JSON.parse(redis.hget('activities', id)) || default_activity_attributes
      rescue StandardError => e
        default_activity_attributes
      end
    end

    def self.default_activity_attributes
      { stepTypes: true, stepsPending: true, stepsRunning:true, stepsFailed: true, stepsFinished: false }.as_json
    end


    protected

    def _process_activity(params)
      activity = Activity.find_by(id: activity_id)

      obj = ActivityMessageProcessor.activity_attributes(activity_id)
      ['stepTypes', 'stepsPending', 'stepsRunning', 'stepsFailed', 'stepsFinished'].reduce(obj) do |memo, key|
        memo[key] = !!params[key] unless params[key].nil?
        memo
      end

      redis.hset('activities', activity_id, obj.to_json)

      activity.touch
    end

    def params_for_activity(params)
      params = ActionController::Parameters.new(params)
      params.require(:activity).permit(:activity_id, :stepTypes, :stepsPending, :stepsRunning, :stepsFailed, :stepsFinished)
    end

  end
end
