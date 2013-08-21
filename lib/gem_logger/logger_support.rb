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

  end
end
