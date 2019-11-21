module ChannelConcerns
  module StreamsManagement

    def self.included(klass)
      klass.instance_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods
      def add_stream_to_list(stream_id)
        previous_value = subscribed_ids || []
        redis.set('SUBSCRIBED_IDS', previous_value.push(stream_id)) unless previous_value.include?(stream_id)
      end

      def remove_stream_from_list(stream_id)
        previous_value = subscribed_ids
        redis.set('SUBSCRIBED_IDS', previous_value.reject{|v| v== stream_id })
      end

      def subscribed_ids
        self.class.subscribed_ids
      end
    end

    module ClassMethods
      def subscribed_ids
        value = redis.get('SUBSCRIBED_IDS')
        return [] unless value
        JSON.parse(value)
      end
    end


  end
end
