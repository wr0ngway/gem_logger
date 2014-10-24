[![Build Status](https://secure.travis-ci.org/wr0ngway/gem_logger.png)](http://travis-ci.org/wr0ngway/gem_logger)
[![Coverage Status](https://coveralls.io/repos/wr0ngway/gem_logger/badge.png?branch=master)](https://coveralls.io/r/wr0ngway/gem_logger?branch=master)

# GemLogger

Allows classes/modules in gems to have logger class/instance methods with a pluggable Logger implementation

## Usage

Include the GemLogger::Logger concern into the classes that need to be able to log.  By default, it will use the standard Ruby logger, if you need a different logger, then configure GemLogger like:

    GemLogger.configure do |config|
    
      # The default logger instance to use
      # (optional, defaults to Logger.new) 
      config.default_logger = CustomLogger.new
    
      # module to include when GemLogger::Logger is included
      # (optional, defaults to GemLogger::BasicLogger) 
      config.logger_concern = SomeModule
    
    end

## Context

It is also possible to add context to your log messages through the context call:

    MyClass.logger.context(:key => 'value').debug("I want context here")
    
as well as include backtraces and context to exceptions by calling the log_exception method with the error and a custom message:

    MyClass.logger.log_exception(StandardError.new('uh oh'), 'This is bad')
    
By default, log_exception uses the ERROR level, but also accepts a level as an option:

    MyClass.logger.log_exception(StandardError.new('uh oh'), 'This is bad', {:level => :debug})
    
Unless otherwise specified, the context is added to the beginning of the log message in a basic key = value format. You can, however, define your own context handler, and pass it in on initialization:

    GemLogger.configure do |config|
      config.context_handler = MyHandler
    end

The class should implement:
  get_context - initialize and return the context
  add_to_context(key, val) - add a given value to the context at key
  remove_from_context(key) - remove the key from the context
  format_msg_with_context(msg) - takes the base log message and adds the context to it, returning the final message.

