require_relative '../../test_helper'

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
        GemLogger.default_logger = Minitest::Mock.new
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
        assert_equal "rails::GemLogger::LoggerSupportTest::#{foosuper.name.split('::').last}::#{foo.name.split('::').last}", foo.logger.fullname
      end
    
      should "have correct logger instance with multiple includes and inheritance" do
        foomod = new_module("FooMod#{@uniq}") { extend ActiveSupport::Concern; include GemLogger::LoggerSupport; }
        foosuper = new_class("FooSuper#{@uniq}") { include foomod; }
        foo = new_class("Foo#{@uniq}", foosuper) { include GemLogger::LoggerSupport; include foomod; }
        assert_equal "rails::GemLogger::LoggerSupportTest::#{foosuper.name.split('::').last}::#{foo.name.split('::').last}", foo.logger.fullname
      end

    end

  end
end
