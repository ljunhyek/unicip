require "logger"   # 표준 라이브러리 선제 로드 (ActiveSupport가 logger 참조하기 전에)

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time through caching; required in config/boot.rb