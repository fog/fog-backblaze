require 'fog/core'
require 'json'

module Fog
  module Backblaze
    autoload :JSONResponse, File.expand_path("../backblaze/json_response", __FILE__)
    autoload :TokenCache, File.expand_path("../backblaze/token_cache", __FILE__)

    extend Fog::Provider
    service(:storage, "Storage")
  end

  module Storage
    autoload :Backblaze, File.expand_path("../storage/backblaze", __FILE__)
  end
end
