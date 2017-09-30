$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "fog/backblaze"

TEST_BUCKET = ENV['B2_BUCKET'] || 'fog-demo-1505931432'

if !ENV['B2_ACCOUNT_ID'] || ENV['B2_ACCOUNT_ID'] == ""
  puts "Missing env B2_ACCOUNT_ID"
  exit 1
end

if !ENV['B2_ACCOUNT_TOKEN'] || ENV['B2_ACCOUNT_TOKEN'] == ""
  puts "Missing env B2_ACCOUNT_TOKEN"
  exit 1
end


CONNECTION = Fog::Storage.new(
  provider: 'backblaze',
  b2_account_id: ENV['B2_ACCOUNT_ID'],
  b2_account_token: ENV['B2_ACCOUNT_TOKEN'],

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
