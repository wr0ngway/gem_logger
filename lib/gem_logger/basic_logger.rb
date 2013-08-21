module GemLogger
  
  # Default support for built in ruby logger
  module BasicLogger
    
    extend ActiveSupport::Concern
    
    module ClassMethods
      def logger
        GemLogger::default_logger
      end
    end
    
  end
  
end
