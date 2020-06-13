require 'logger'
require 'pp'

$:.push(File.expand_path("../../lib", __FILE__))

require_relative "../lib/fog/backblaze"

if !ENV['B2_ACCOUNT_ID'] || ENV['B2_ACCOUNT_ID'] == ""
  puts "Missing env B2_ACCOUNT_ID"
  exit 1
end

if !ENV['B2_ACCOUNT_TOKEN'] || ENV['B2_ACCOUNT_TOKEN'] == ""
  puts "Missing env B2_ACCOUNT_TOKEN"
  exit 1
end

connection = Fog::Storage.new(
  provider: 'backblaze',
  b2_account_id: ENV['B2_ACCOUNT_ID'],
  b2_account_token: ENV['B2_ACCOUNT_TOKEN'],

  logger: ENV['DEBUG'] ? Logger.new(STDOUT) : nil
)

## Create Bucket

bucket_name = "fog-demo-#{Time.now.to_i}"
directory = connection.directories.create(key: bucket_name, public: false)

at_exit do
  puts "removing a bucket #{directory.key}"
  directory.destroy_recursive
end


## Create File

file = directory.files.create(
  key: 'example.html',
  body: File.open(__FILE__)
)

## Read Files

directory.files.each do |file|
  p file
  puts
  puts file.body
  puts
end

