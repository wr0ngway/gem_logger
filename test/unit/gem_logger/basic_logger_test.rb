require_relative '../../test_helper'

module GemLogger
  class BasicLoggerTest < Minitest::Should::TestCase
    
    context "BasicLogger" do
      
      should "define a logger class method" do
        class MyClass
          include GemLogger::BasicLogger
        end
        assert MyClass.respond_to?(:logger)
      end
      
    end
    
  end
end
