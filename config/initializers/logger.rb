# Fix Logger compatibility issue for Ruby 3.1+
require 'logger'

# Ensure Logger constants are available before ActiveSupport loads
unless defined?(Logger)
  require 'logger'
end

# Pre-load Logger::Severity constants
Logger::Severity.constants rescue nil