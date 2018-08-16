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

bucket_name = "fog-demo-#{Time.now.to_i}"

# creating bucket with all possible options

directory = connection.directories.create(
  key: bucket_name,
  public: false,
  bucket_info: {
    test_key: "Test value"
  },
  lifecycle_rules: [
    {
      fileNamePrefix: "aaa",
      daysFromUploadingToHiding: 10,
      daysFromHidingToDeleting: 20
    }
  ],
  cors_rules: [
    {
      corsRuleName: "downloadFromAnyOrigin",
      allowedOrigins: ["https"],
      allowedHeaders: ["range"],
      allowedOperations: [
        "b2_download_file_by_id",
        "b2_download_file_by_name"
      ],
      exposeHeaders: ["x-bz-content-sha1"],
      maxAgeSeconds: 3600
    }
  ]
)

p directory

# delete new bucket on exit
at_exit do
  directory.files.each do |file|
    puts "removing file #{file.key}"
    p file.destroy
  end
  puts "removing a bucket #{directory.key}"
  p directory.destroy
end

# list directories (buckets)
p connection.directories

# upload in new bucket
file = directory.files.create(
  key:    'Gemfile.lock',
  body:   File.open("./icco_example.rb"),
  public: true
)