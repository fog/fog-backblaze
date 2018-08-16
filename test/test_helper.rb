$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'bundler/setup'
require 'yaml'
require 'pp'
require "fog/backblaze"

B2_CREDENTIALS = YAML::load_file(File.join(__dir__, 'credentials.yaml'))
TEST_BUCKET    = B2_CREDENTIALS['bucket_name']

CONNECTION = Fog::Storage.new(
  provider: 'backblaze',
  b2_key_id: B2_CREDENTIALS['key_id'],
  b2_key_token: B2_CREDENTIALS['key_token'],

  b2_account_id: B2_CREDENTIALS['account_id'],
  b2_account_token: B2_CREDENTIALS['account_token'],

  logger: !ENV['FOG_DEBUG'] && begin
    require 'logger'
    logger = Logger.new(STDOUT)
    logger.formatter = proc {|severity, datetime, progname, msg|
      "#{severity.to_s[0]} - #{datetime.strftime("%T.%L")}: #{msg}\n"
    }
    logger
  end,

#  token_cache: 'test/token_cache.txt',
  token_cache: nil
)

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new)
def MiniTest.filter_backtrace(bt)
  bt
end
