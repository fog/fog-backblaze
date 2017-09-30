require_relative 'backblaze/version'
require_relative 'backblaze/token_cache'

require 'fog/core'
require 'json'

#require_relative 'backblaze/storage'

module Fog
  module Backblaze
    extend Fog::Provider
    service(:storage, "Storage")

  end
end
