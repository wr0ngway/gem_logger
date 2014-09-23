module GemLogger
  module LoggerSupport

    extend ActiveSupport::Concern

    included do
      # A guard to prevent misuse, may just want a log message instead of a hard fail
      if self.class == Module && ! self.singleton_class.included_modules.include?(ActiveSupport::Concern)
        raise ArgumentError, "module that includes #{self.name} must be an ActiveSupport::Concern"
      end

      include GemLogger.logger_concern

      delegate :logger, :log_exception, :log_warning, :log_message, :to => "self.class"
    end

    module ClassMethods
      # @deprecated Consider using {#logger.context(:exception => exception.class).error("Exception: ...")} instead
      def log_exception(exception, opts={})
        logger.error("Exception #{generate_message(exception, opts)}")
      end

      def log_warning(exception, opts={})
        logger.warn("Warning #{generate_message(exception, opts)}")
      end

      def log_message(group, message, opts={})
        log_exception({:error_class   => group,
                       :error_message => message },
                      opts)
      end

      def log_encode(str)
        str.encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '')
      end

      def generate_message(exception, opts)
        class_name = self.name
        method_name = caller.first.gsub(/.*`(.*)'$/, '\1') rescue nil
        opts = {:controller => class_name, :action => method_name}.merge(opts)

        message_prefix = opts[:message_prefix] || ''
        message_prefix += ' ' unless message_prefix.strip.size == 0

        "#{log_encode(message_prefix)}#{log_encode(exception.inspect)}, #{log_encode(opts.inspect)}:\n#{exception.backtrace.collect {|x| log_encode(x)}.join("\n") rescue 'no backtrace'}"
      end

    end


    module ContextLoggerCommon
      # @param [Hash] added_context - A hash containing context that will be added to the log messages produced by the
      # returned logger
      # @returns [LogContextLogger] - logger with the added context
      def context(added_context)
        LogContextLogger.new(self.logger, self.log_context.merge(added_context))
      end

      # Adds an event_type to the context
      # @param [Symbol] event_type - The event type, which will be added to the context of this log statement
      def event_context(event_type)
        context(:event_type => event_type)
      end

      # Adds an exception class to the context
      # @param [Exception] exception
      def exception_context(exception)
        context(:exception => exception.class.to_s)
      end

      # Logs an exception, including the backtrace.
      # @param [Exception] exception
      # @param [String] message
      # @option [Symbol] :level - The log level to log the message at (default :error)
      def log_exception(e, message, options = {})
        level = options.delete(:level) || :error
        backtrace = e.backtrace.try{ |b| b.join("\n") } || '(no backtrace)'
        exception_context(e).send(level, "#{message}: #{e} #{backtrace}")
      end
    end

    # The base context logger, intended to extend a Log4r logger
    module LogContext
      include ContextLoggerCommon

      def log_context
        {}
      end

      def logger
        self
      end
    end

    LogContextLogger = Struct.new(:logger, :log_context) do
      include ContextLoggerCommon
      include GemLogger.context_handler

      [:debug, :info, :warn, :error, :fatal].each do |method|
        define_method(method) { |msg| self.log(method, msg) }
      end

      def log(level, msg)
        existing_context = get_context
        self.log_context.each { |k,v| add_to_context(k, v) }
        msg = format_msg_with_context(msg)
        self.logger.send(level, msg)
      ensure
        self.log_context.each { |k,v| remove_from_context(k) }
        existing_context.each { |k,v| add_to_context(k, v) }
      end
    end

  end
end
