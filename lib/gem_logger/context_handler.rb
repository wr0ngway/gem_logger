module GemLogger
  module ContextHandler
    extend ActiveSupport::Concern

    # Initializes and returns context hash.
    def get_context
      @context_hash ||= {}
    end

    def add_to_context(key, value)
      @context_hash[key.to_s] = value.to_s
    end

    def remove_from_context(key)
      @context_hash.delete(key.to_s)
    end

    # Adds the keys/values to the message to be logged in a basic [key=val] format.
    def format_msg_with_context(msg)
      if @context_hash.keys.length > 0
        msg_context = '['
        @context_hash.each do |k, v|
          msg_context += "#{k}=#{v} "
        end
        msg_context += '] '
        msg = msg.prepend(msg_context)
      end
      msg
    end
  end
end
