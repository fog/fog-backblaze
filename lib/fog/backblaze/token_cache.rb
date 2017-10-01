# Each request must have authentication header, recieved from b2_authorize_account
# Authentication token is active for 24 hours, same as uploadUrl. To make things faster we keep it in cache
#
# Avaliable cache storages: file, memory, null
#
# To create own cache storage (stored in redis for example)
#
#   class RedisTokenCache < Fog::Backblaze::TokenCache
#     def initialize(redis_url)
#       @redis = Redis.new(redis_url)
#       super()
#     end
#     def load_data
#       raw_data = @redis.get("b2_token_cache")
#       raw_data ? JSON.parse(raw_data) : {}
#     end
#     def save_data
#       @redis.set("b2_token_cache", JSON.pretty_generate(@data))
#     end
#   end
#   
#   Fog::Storage.new(provider: 'backblaze', ..., token_cache: RedisTokenCache.new)
#

module Fog
  module Backblaze
  end
end

class Fog::Backblaze::TokenCache

  def initialize
    @data = load_data || {}
  end

  def load_data
  end

  def save_data
  end

  TTLS = {
    auth_response: 3600 * 24,
    buckets: 3600 * 24,
    upload_url: 3600 * 24
  }

  def fetch(field)
    if result = access_part(field)
      result
    else
      result = yield
      write_part(field, result, TTLS[field])
      save_data
      result
    end
  end

  def auth_response
    access_part(:auth_response)
  end

  def auth_response=(value)
    write_part(:auth_response, value, 3600 * 24)
    save_data
  end

  def buckets
    access_part(:buckets)
  end

  def buckets=(value)
    write_part(:buckets, value, 3600 * 24)
    save_data
  end

  def upload_url
    
  end

  def access_part(name)
    name = name.to_s
    if @data[name] && ::DateTime.parse(@data[name]['expires_at']).to_time > ::Time.now
      @data[name]['value']
    end
  end

  def write_part(name, value, ttl = 3600)
    ttl = 3600 if ttl.nil?
    name = name.to_s
    if value.nil?
      @data.delete(name)
    else
      @data[name] = {
        'value' => value,
        'expires_at' => ::Time.at(::Time.now + ttl - 1).to_s
      }
    end
  end

  def reset
    @data = {}
    save_data
  end

  # stored in local file
  class FileTokenCache < Fog::Backblaze::TokenCache

    def initialize(file)
      @file = file
      super()
    end

    def load_data
      if File.exist?(@file)
        JSON.parse(File.open(@file, 'rb', &:read))
      else
        {}
      end
    end

    def save_data
      File.open(@file, 'wb') do |f|
        f.write(JSON.pretty_generate(@data) + "\n")
      end
    end
  end

  # black hole, always clean cache
  class NullTokenCache < Fog::Backblaze::TokenCache
    def write_part(name, value, ttl = 3600)
    end
  end
end
