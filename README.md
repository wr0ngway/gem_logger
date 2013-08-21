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

