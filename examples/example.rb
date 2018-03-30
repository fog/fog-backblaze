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

  #b2_bucket_name: ENV['B2_BUCKET'],
  #b2_bucket_id: '111222333444',

  logger: ENV['DEBUG'] ? Logger.new(STDOUT) : nil
)

connection.delete_bucket("fog-smoke-test") rescue nil

puts "Put a bucket..."
puts "----------------"
pp connection.put_bucket("fog-smoke-test", public: true).json

puts
puts "Get the bucket..."
puts "-----------------"
pp connection.get_bucket("fog-smoke-test").json

puts
puts "Put a test file..."
puts "---------------"
pp connection.put_object("fog-smoke-test", "my file", "THISISATESTFILE").json

puts
puts "Get the test file..."
puts "---------------"
p connection.get_object("fog-smoke-test", "my file")

puts
puts "Head file..."
puts "---------------"
pp connection.head_object("fog-smoke-test", "my file").headers

puts
puts "Object URL..."
puts "---------------"
p connection.get_object_url("fog-smoke-test", "my file")

puts
puts "Delete the test file..."
puts "---------------"
pp connection.delete_object("fog-smoke-test", "my file").json

puts
puts "Delete the bucket..."
puts "------------------"
pp connection.delete_bucket("fog-smoke-test").json
puts
