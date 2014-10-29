require_relative '../../test_helper'
require 'active_support/core_ext/module/delegation'

module GemLogger
  class LoggerSupportTest < Minitest::Should::TestCase

    setup do
      @uniq = SecureRandom.uuid.gsub("-", "")
    end

    teardown do
      LoggerSupportTest.constants.grep(/^Foo/).each do |c|
        LoggerSupportTest.send(:remove_const, c)
      end
    end

    def new_module(module_name, &block)
      mod = self.class.const_set module_name, Module.new
      mod.class_eval(&block)
      mod
    end

    # can't do this dynamically as the class name needs to be set at inheritance time for lumber to work
    def new_class(class_name, super_class=nil, &block)
      s = "class #{class_name}"
      s << " < #{super_class}" if super_class
      s << "; end"

      eval(s)
      clazz = self.class.const_get(class_name)
      clazz.class_eval(&block)
      clazz
    end

    context "BasicLogger" do

      setup do
        @old_default_logger = GemLogger.default_logger

        mock = Minitest::Mock.new
        def mock.extend(mod)
          self
        end

        GemLogger.default_logger = mock
      end

      teardown do
        GemLogger.default_logger.verify
        GemLogger.default_logger = @old_default_logger
      end

      should "have a logger instance accessible from an instance method" do
        foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; def member_method; logger.debug('hi'); end; }
        assert foo.new.respond_to?(:logger)
        foo.logger.expect(:debug, nil, ['hi'])
        foo.new.member_method
      end

      should "have a logger instance accessible from a class method " do
        foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; def self.class_method; logger.debug('hi'); end; }
        assert foo.respond_to?(:logger)
        foo.logger.expect(:debug, nil, ['hi'])
        foo.class_method
      end

      should "have a logger instance when in a nested module" do
        foomod = new_module("FooMod#{@uniq}") { extend ActiveSupport::Concern; include GemLogger::LoggerSupport; }
        foo = new_class("Foo#{@uniq}") { include foomod; def member_method; logger.debug('hi'); end; }
        assert foo.new.respond_to?(:logger)
        foo.logger.expect(:debug, nil, ['hi'])
        foo.new.member_method
      end

      should "fail when included in a module that is not a Concern" do
        assert_raises(ArgumentError) do
          new_module("FooMod#{@uniq}") { include GemLogger::LoggerSupport; }
        end
      end

      should "have a log_exception method accessible from an instance method" do
        foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; def member_method; log_exception(RuntimeError.new("hell")); end; }
        assert foo.new.respond_to?(:log_exception)
        foo.logger.expect(:error, nil, [/.*/])
        foo.new.member_method
      end

      should "have a log_exception method accessible from a class method " do
        foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; def self.class_method; log_exception(RuntimeError.new("hell")); end; }
        assert foo.respond_to?(:log_exception)
        foo.logger.expect(:error, nil, [/.*/])
        foo.class_method
      end

      should "log_exception should populate class name as controller and method name as action" do
        foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; def self.class_method; log_exception(RuntimeError.new("hell")); end; }
        foo.logger.expect(:error, nil, [/.*/])
        foo.class_method
      end

      should "not raise exception on bad encoding" do
        foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; def self.class_method; log_exception(RuntimeError.new("\xE2".force_encoding('ASCII-8BIT'))); end; }
        foo.logger.expect(:error, nil, [/.*/])
        foo.class_method
      end

      context 'Generate Message' do
        should 'properly generate messages with a message prefix' do
          foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; }
          assert_match /^prefix /, foo.generate_message(StandardError.new('Hello'), {:message_prefix => 'prefix'})
        end

        should 'properly generate messages with a blank message prefix' do
          foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; }
          assert_match /^#<StandardError: Hello>/, foo.generate_message(StandardError.new('Hello'), {:message_prefix => ''})
        end

        should 'properly generate messages with no message prefix' do
          foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; }
          assert_match /^#<StandardError: Hello>/, foo.generate_message(StandardError.new('Hello'), {})
        end
      end

    end

    context "logger with added context" do

      class Context
        class << self
          attr_accessor :values
        end

        def self.get_context
          self.values ||= {}
        end

        def self.add_to_context(key, value)
          get_context[key] = value
        end

        def self.remove_from_context(key)
          get_context.delete(key)
        end
      end

      module TestContextHandler
        extend ActiveSupport::Concern

        delegate :get_context, :add_to_context, :remove_from_context, :to => Context

        def format_msg_with_context(msg)
          msg
        end

      end

      setup do
        class Foo; include GemLogger::LoggerSupport; end
        GemLogger.context_handler = TestContextHandler
      end

      should "add the context to generated messages" do

        Context.expects(:add_to_context).with("ctx", "1")
        Context.expects(:remove_from_context).with('ctx')
        Foo.logger.expects(:info).with("msg")
        Foo.logger.context("ctx" => "1").info("msg")
      end

      should "allow symbols as contexts" do
        Context.expects(:add_to_context).with(:ctx, "1")
        Context.expects(:remove_from_context).with(:ctx)

        Foo.logger.context(:ctx => "1").info("msg")
      end

      should "implement debug" do
        Foo.logger.expects(:debug).with("msg")
        Foo.logger.context(:ctx => "1").debug("msg")
      end

      should "implement info" do
        Foo.logger.expects(:info).with("msg")
        Foo.logger.context(:ctx => "1").info("msg")
      end

      should "implement warn" do
        Foo.logger.expects(:warn).with("msg")
        Foo.logger.context(:ctx => "1").warn("msg")
      end

      should "implement error" do
        Foo.logger.expects(:error).with("msg")
        Foo.logger.context(:ctx => "1").error("msg")
      end

      should "implement fatal" do
        Foo.logger.expects(:fatal).with("msg")
        Foo.logger.context(:ctx => "1").fatal("msg")
      end

      should 'allow context to be chained' do
        Context.expects(:add_to_context).with('ctx', '1')
        Context.expects(:remove_from_context).with('ctx')
        Context.expects(:add_to_context).with('ctx2', '2')
        Context.expects(:remove_from_context).with('ctx2')
        Foo.logger.expects(:info).with("msg")

        Foo.logger.context("ctx" => "1").context("ctx2" => "2").info("msg")
      end

      context "event_context" do
        should "add the event_type as context" do
          Context.expects(:add_to_context).with(:event_type, :test_event)
          Context.expects(:remove_from_context).with(:event_type)

          Foo.logger.expects(:info).with("msg")
          Foo.logger.event_context(:test_event).info("msg")
        end

        should "include the context of the logger used" do
          Context.expects(:add_to_context).with(:event_type, :test_event)
          Context.expects(:remove_from_context).with(:event_type)
          Context.expects(:add_to_context).with(:ctx, '1')
          Context.expects(:remove_from_context).with(:ctx)

          Foo.logger.expects(:error).with("msg")
          Foo.logger.context(:ctx => "1").event_context(:test_event).error("msg")
        end

        should 'restore previous log context after logging' do
          Context.stubs(:get_context).returns({'foo' => 'bar'})
          Context.expects(:add_to_context).with(:event_type, {'foo' => 'baz'})
          Context.expects(:remove_from_context).with(:event_type)
          Context.expects(:add_to_context).with('foo', 'bar')

          Foo.logger.event_context('foo' => 'baz').info("msg")
        end
      end

      context "exception_context" do
        should "add the exception class as context" do
          Context.expects(:add_to_context).with(:exception, 'StandardError')
          Context.expects(:remove_from_context).with(:exception)

          Foo.logger.expects(:info).with("msg")
          Foo.logger.exception_context(StandardError.new).info("msg")
        end
      end

      context "log_exception" do
        should "add the exception class as context" do
          Context.expects(:add_to_context).with(:exception, 'StandardError')
          Context.expects(:remove_from_context).with(:exception)

          Foo.logger.expects(:error)
          Foo.logger.log_exception(StandardError.new, "msg")
        end

        should "log the backtrace" do
          Foo.logger.expects(:error).with("msg: err (no backtrace)")
          Foo.logger.log_exception(StandardError.new("err"), "msg")
        end

        should 'allow the level to be changed as an option' do
          Foo.logger.expects(:warn).with("msg: err (no backtrace)")
          Foo.logger.log_exception(StandardError.new("err"), "msg", :level => :warn)
        end
      end
    end

    context "lumber integration" do

      setup do
        require 'lumber'

        yml = <<-EOF
log4r_config:
  pre_config:
    root:
      level: 'DEBUG'
  loggers:
    - name: "rails"
      level: DEBUG
  outputters: []
        EOF

        cfg = Log4r::YamlConfigurator
        cfg.load_yaml_string(yml)
        logger = Log4r::Logger['rails']
        sio = StringIO.new
        logger.outputters = [Log4r::IOOutputter.new("sbout", sio)]

        Log4r::YamlConfigurator.stub(:load_yaml_file, nil) do
          root = File.expand_path("../../..", __FILE__)
          Lumber.init(:root => root, :env => 'test', :config_file => __FILE__)
        end

        @old_logger_concern = GemLogger.logger_concern
        GemLogger.logger_concern = Lumber::LoggerSupport
      end

      teardown do
        GemLogger.logger_concern = @old_logger_concern
      end

      should "have a logger instance accessible from an instance method" do
        foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; }
        assert_equal "rails::GemLogger::LoggerSupportTest::#{foo.name.split('::').last}", foo.new.logger.fullname
      end

      should "have a logger instance accessible from a class method " do
        foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; }
        assert_equal "rails::GemLogger::LoggerSupportTest::#{foo.name.split('::').last}", foo.logger.fullname
      end

      should "have a logger instance when in a nested module" do
        foomod = new_module("FooMod#{@uniq}") { extend ActiveSupport::Concern; include GemLogger::LoggerSupport; }
        foo = new_class("Foo#{@uniq}") { include foomod; }
        assert_equal "rails::GemLogger::LoggerSupportTest::#{foo.name.split('::').last}", foo.logger.fullname
      end

      should "have correct logger instance with multiple includes" do
        foomod = new_module("FooMod#{@uniq}") { extend ActiveSupport::Concern; include GemLogger::LoggerSupport; }
        foo = new_class("Foo#{@uniq}") { include GemLogger::LoggerSupport; include foomod; }
        assert_equal "rails::GemLogger::LoggerSupportTest::#{foo.name.split('::').last}", foo.logger.fullname
      end

      should "have correct logger instance with includes and inheritance" do
        foosuper = new_class("FooSuper#{@uniq}") { include GemLogger::LoggerSupport; }
        foo = new_class("Foo#{@uniq}", foosuper) { }
        assert_equal "rails::GemLogger::LoggerSupportTest::#{foo.name.split('::').last}", foo.logger.fullname
      end

      should "have correct logger instance with multiple includes and inheritance" do
        foomod = new_module("FooMod#{@uniq}") { extend ActiveSupport::Concern; include GemLogger::LoggerSupport; }
        foosuper = new_class("FooSuper#{@uniq}") { include foomod; }
        foo = new_class("Foo#{@uniq}", foosuper) { include GemLogger::LoggerSupport; include foomod; }
        assert_equal "rails::GemLogger::LoggerSupportTest::#{foo.name.split('::').last}", foo.logger.fullname
      end

    end

  end
end
