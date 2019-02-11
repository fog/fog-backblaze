require 'fog/core'

module Fog
  module Backblaze
    autoload :JSONResponse, File.expand_path("../backblaze/json_response", __FILE__)
    autoload :TokenCache, File.expand_path("../backblaze/token_cache", __FILE__)

    autoload :Storage, File.expand_path("../backblaze/storage", __FILE__)

    extend Fog::Provider
    service(:storage, "Storage")
  end
end
