$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'faceapp'
require 'webmock/rspec'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end
