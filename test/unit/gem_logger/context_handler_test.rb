require_relative '../../test_helper'

module GemLogger
  class ContextHandlerTest < Minitest::Should::TestCase

    setup do
      class MyClass
        include GemLogger::ContextHandler
      end
    end
    should "pass add_to_context to Log4r put" do
      Log4r::MDC.expects(:put).with('key', 'value')
      MyClass.new.add_to_context('key', 'value')
    end

    should "convert add_to_context args to strings" do
      Log4r::MDC.expects(:put).with('key', 'value')
      MyClass.new.add_to_context(:key, :value)
    end

    should 'get existing Log4r context' do
      Log4r::MDC.put('some', 'thing')
      context = MyClass.new.get_context
      assert_equal 'thing', context['some']
      # Clean up.
      Log4r::MDC.remove('some')
    end

    should "pass remove_from_context to Log4r remove" do
      Log4r::MDC.expects(:remove).with('key')
      MyClass.new.remove_from_context('key')
    end

    should "convert remove_from_context args to strings" do
      Log4r::MDC.expects(:remove).with('key')
      MyClass.new.remove_from_context(:key)
    end
  end
end
