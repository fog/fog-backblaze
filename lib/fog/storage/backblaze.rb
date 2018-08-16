require 'json'
require 'digest'
require 'cgi'

class Fog::Storage::Backblaze < Fog::Service
  #requires 
  recognizes :b2_account_id, :b2_account_token, :b2_key_id, :b2_key_token,
             :b2_bucket_name, :b2_bucket_id, :token_cache, :logger

  model_path 'fog/storage/backblaze/models'
  model       :directory
  collection  :directories
  model       :file
  collection  :files

  autoload :Mock, File.expand_path("../backblaze/mock", __FILE__)
  autoload :Real, File.expand_path("../backblaze/real", __FILE__)
end
