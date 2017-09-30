require_relative 'backblaze/version'

require 'fog/core'
require 'json'

#require_relative 'backblaze/storage'

module Fog
  module Backblaze
    extend Fog::Provider
    service(:storage, "Storage")

    class TokenCache

      def initialize(file)
        @file = file
        @data = if File.exist?(@file)
          JSON.parse(File.open(@file, 'rb', &:read))
        else
          {}
        end
      end

      def save_file
        File.open(@file, 'wb') do |f|
          f.write(JSON.pretty_generate(@data) + "\n")
        end
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
          save_file
          result
        end
      end

      def auth_response
        access_part(:auth_response)
      end

      def auth_response=(value)
        write_part(:auth_response, value, 3600 * 24)
        save_file
      end

      def buckets
        access_part(:buckets)
      end

      def buckets=(value)
        write_part(:buckets, value, 3600 * 24)
        save_file
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
        @data[name] = {
          'value' => value,
          'expires_at' => ::Time.at(::Time.now + ttl - 1).to_s
        }
      end

      def reset
        @data = {}
        save_file
      end

    end

    class MemoryTokenCache < TokenCache
      def initialize
        @data = {}
      end

      def save_file
      end
    end

    class NullTokenCache < MemoryTokenCache
      def write_part(name, value, ttl = 3600)
      end
    end

  end
end
