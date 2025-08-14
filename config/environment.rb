# Fix Logger compatibility for Ruby 3.1+
require "logger"

# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!