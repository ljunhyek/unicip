# Fix Logger compatibility issue for Ruby 3.1+ and Rails 6.1
require "logger"
Logger # Force Logger constant loading

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time through caching; required in config/boot.rb