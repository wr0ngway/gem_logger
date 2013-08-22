require "gem_logger/version"

require 'logger'
require 'active_support/concern'
require 'active_support/core_ext/module/delegation'

require "gem_logger/basic_logger"
require "gem_logger/logger_support"

# To configure gem_logger, add something like the
# following to an initializer (defaults shown):
#
#    GemLogger.configure do |config|
#
#      # The default logger instance to use
#      # (optional, defaults to Logger.new) 
#      config.default_logger = CustomLogger.new
#
#      # module to include when GemLogger::LoggerSupport is included
#      # (optional, defaults to GemLogger::BasicLogger) 
#      config.logger_concern = SomeModule
#
#    end
#
module GemLogger
  
  # Allows configuring via class accessors
  class << self
    # The logger concern (ActiveSupport::Concern) to include when clients include GemLogger::Logger
    # The module needs to cause a class level "logger" method (returning the logger instance) to be deSupportfined on the client
    attr_accessor :logger_concern
  end
  
  # default values
  self.logger_concern = GemLogger::BasicLogger

  # The default_logger to use with GemLogger::BasicLogger
  def self.default_logger
    @default_logger ||= ::Logger.new(STDOUT)
  end

  # Set the default_logger to use with GemLogger::BasicLogger
  def self.default_logger=(default_logger)
    @default_logger = default_logger
  end
  
  # Allows configuring via class accessors
  def self.configure
    yield self
  end
  
end
