module Actions
  module Layout
    class InvalidDataParams < StandardError
      attr_accessor :errors

      def initialize(message = nil)
        super(message)
        @errors = message
        #@msg = html_error_message([message].flatten)
      end

      def html_error_message(error_messages)
        ['<ul>', error_messages.map do |msg|
          ['<li>',msg,'</li>']
        end, '</ul>'].flatten.join('')
      end

    end

  end
end
