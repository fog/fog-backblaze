require 'json'
require 'digest'
require 'cgi'

class Fog::Backblaze::Storage < Fog::Service
  #requires 
  recognizes :b2_account_id, :b2_account_token, :b2_key_id, :b2_key_token,
             :b2_bucket_name, :b2_bucket_id, :token_cache, :logger

  model_path 'fog/backblaze/storage/models'
  model       :directory
  collection  :directories
  model       :file
  collection  :files

  autoload :Mock, File.expand_path("../storage/mock", __FILE__)
  autoload :Real, File.expand_path("../storage/real", __FILE__)
end
