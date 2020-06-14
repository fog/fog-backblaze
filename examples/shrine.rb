# gem install activerecord sqlite3 shrine rack-test shrine-fog

require 'active_record'
require 'rack/test'
require 'shrine'
require 'sqlite3'
require "shrine/storage/fog"
require 'irb'

$:.push(File.expand_path("../../lib", __FILE__))
require_relative "../lib/fog/backblaze"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define(version: 1) do
  create_table :examples do |t|
    t.text :body
    t.text :picture_data
  end
end

store_b2 = Fog::Storage.new(
  provider: 'backblaze',
  b2_key_id: '001e4484b4856cc0000000001',
  b2_key_token: 'K0019gknHGO/KNLfS5eBthgHn5ebGjk',
  b2_bucket_name: 'ddddd123'
)

Shrine.storages[:store] = Shrine::Storage::Fog.new(
  connection: store_b2,
  directory: "ddddd123",
)

Shrine.storages[:cache] = Shrine::Storage::Fog.new(
  connection: store_b2,
  directory: "ddddd123",
)
 
Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data
Shrine.plugin :restore_cached_data 

class ImageUploader < Shrine
end

class Example < ActiveRecord::Base
  include ImageUploader::Attachment(:picture)
end

record = Example.new(picture: Rack::Test::UploadedFile.new('test/fixtures/pic.jpg', 'image/jpeg', true))

record.save!

puts record.picture_data
puts "Picture URL: #{record.picture_url}" 
