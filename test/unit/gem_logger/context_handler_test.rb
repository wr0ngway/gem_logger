require_relative '../../test_helper'

module GemLogger
  class ContextHandlerTest < Minitest::Should::TestCase

    setup do
      class MyClass
        include GemLogger::ContextHandler
      end
    end

    should "return empty hash on get_context" do
      assert_equal Hash.new, MyClass.new.get_context
    end

    should 'add given arguments to context on add_context' do
      klass = MyClass.new
      klass.get_context
      klass.add_to_context('foo', 'bar')
      assert_equal Hash['foo', 'bar'], klass.get_context
    end

    should "convert add_to_context args to strings" do
      klass = MyClass.new
      klass.get_context
      klass.add_to_context(:foo, :bar)
      assert_equal Hash['foo', 'bar'], klass.get_context
    end

    should "pass remove_from_context to Log4r remove" do
      klass = MyClass.new
      klass.get_context
      klass.remove_from_context('foo')
      assert_equal Hash.new, klass.get_context
    end

    should "convert remove_from_context args to strings" do
      klass = MyClass.new
      klass.get_context
      klass.add_to_context('foo', 'bar')
      klass.remove_from_context(:foo)
      assert_equal Hash.new, klass.get_context
    end
  end
end
