require 'log4r'

module GemLogger
  module ContextHandler
    extend ActiveSupport::Concern

    # Log4r::MDC.get_context returns a copy of the log context that is not
    # modified when we remove the context variables added
    def get_context
      Log4r::MDC.get_context
    end

    def add_to_context(key, value)
      Log4r::MDC.put(key.to_s, value.to_s)
    end

    def remove_from_context(key)
      Log4r::MDC.remove(key.to_s)
    end
  end
end
