require_relative '../test_helper'

class GemLoggerTest < MiniTest::Should::TestCase
  
  context "configure" do
    
    should "provide a default value for default_logger" do
      GemLogger.default_logger = nil
      assert_instance_of Logger, GemLogger.default_logger
    end
    
    should "provide a default value for logger_concern" do
      assert_equal GemLogger::BasicLogger, GemLogger.logger_concern
    end

    should "allow config through #configure" do
      old_logger = GemLogger.default_logger
      old_concern = GemLogger.logger_concern

      begin
        logger = Logger.new(STDOUT)
        concern = Module.new { FOO = 'bar' }
        GemLogger.configure do |config|
          config.default_logger = logger
          config.logger_concern = concern
        end
        
        assert_equal logger, GemLogger.default_logger
        assert_equal concern, GemLogger.logger_concern
      ensure
        GemLogger.default_logger = old_logger
        GemLogger.logger_concern = old_concern
      end
    end
    
  end
  
end
