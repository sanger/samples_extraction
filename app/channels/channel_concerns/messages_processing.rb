module ChannelConcerns
  module MessagesProcessing
    def self.included(klass)
      klass.instance_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods

      def message_processors
        @message_processors
      end

      def process_message(message_from_frontend)
        message_processors.each do |processor|
          if processor.interested_in?(message_from_frontend)
            processor.process(message_from_frontend)
          end
        end
      end

      def create_message_processors!
        @message_processors ||= self.class.registered_message_processor_classes.map do |p|
          p.new(channel: self)
        end
      end
    end

    module ClassMethods
      def register_message_processor(message_processor_class)
        @registered_message_processor_classes ||= []
        @registered_message_processor_classes.push(message_processor_class)
      end

      def registered_message_processor_classes
        @registered_message_processor_classes
      end
    end
  end
end
