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
    # The module needs to cause a class level "logger" method (returning the logger instance) to be defined on the client
    attr_accessor :logger_concern
    attr_accessor :context_handler
  end

  # default values
  self.logger_concern = GemLogger::BasicLogger
  self.context_handler = GemLogger::ContextHandler

  # The default_logger to use with GemLogger::BasicLogger
  def self.default_logger
    @default_logger ||= ::Logger.new(STDOUT).extend(LoggerSupport::LogContext)
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
