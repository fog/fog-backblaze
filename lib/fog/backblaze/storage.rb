require 'json'
require 'digest'

class Fog::Storage::Backblaze < Fog::Service
  requires :b2_account_id, :b2_account_token
  recognizes :b2_bucket_name, :b2_bucket_id, :token_cache, :logger

  model_path 'fog/backblaze/models'
  model       :directory
  collection  :directories
  model       :file
  collection  :files

  class Mock
    #include Integrity

    def self.data
      @data ||= Hash.new do |hash, key|
        hash[key] = {}
      end
    end

    def self.reset
      @data = nil
    end

    def initialize(options={})
      @b2_account_id = options[:b2_account_id]
      @b2_account_token = options[:b2_account_token]
      @path = '/v1/AUTH_1234'
      @containers = {}
    end

    def data
      self.class.data[@softlayer_username]
    end

    def reset_data
      self.class.data.delete(@softlayer_username)
    end

    def change_account(account)
      @original_path ||= @path
      version_string = @original_path.split('/')[1]
      @path = "/#{version_string}/#{account}"
    end

    def reset_account_name
      @path = @original_path
    end

  end

  class Real
    attr_reader :token_cache, :options

    def initialize(options = {})
      @options = options
      @logger = @options[:logger] || begin
        require 'logger'
        Logger.new("/dev/null")
      end

      @token_cache = if options[:token_cache].nil?
        Fog::Backblaze::TokenCache.new
      elsif options[:token_cache] === false
        Fog::Backblaze::TokenCache::NullTokenCache.new
      elsif token_cache.is_a?(Fog::Backblaze::TokenCache)
        token_cache
      else
        Fog::Backblaze::TokenCache::FileTokenCache.new(options[:token_cache])
      end
    end

    def logger
      @logger
    end

    def put_bucket(key, extra_options)
      options = {
        accountId: @options[:b2_account_id],
        bucketType: extra_options[:public] ? 'allPublic' : 'allPrivate',
        bucketName: key,
      }.merge(extra_options)

      response = b2_command(:b2_create_bucket, body: options)
    end

    def list_buckets
      response = b2_command(:b2_list_buckets, body: {accountId: @options[:b2_account_id]})

      ##pp response

      response.json['buckets']
    end

    def head_object(bucket_name, file_path)
      file_url = get_download_url(bucket_name, file_path)

      result = b2_command(nil,
        method: :head,
        url: file_url
      )

      if result.status == 404
        raise Fog::Errors::NotFound, "Can not find #{file_path.inspect} in bucket #{bucket_name}"
      end

      if result.status >= 400
        raise Fog::Errors::NotFound, "Backblaze respond with status = #{result.status} - #{result.reason_phrase}"
      end

      result
    end

    def put_object(bucket_name, file_path, content)
      upload_url = @token_cache.fetch("upload_url/#{bucket_name}") do
        bucket_id = _get_bucket_id(bucket_name)
        unless bucket_id
          raise Fog::Errors::NotFound, "Can not find bucket #{bucket_name.inspect}"
        end
        result = b2_command(:b2_get_upload_url, body: {bucketId: _get_bucket_id(bucket_name)})
        result.json
      end

      response = b2_command(nil,
        url: upload_url['uploadUrl'],
        body: content,
        headers: {
          'Authorization': upload_url['authorizationToken'],
          'Content-Type': 'b2/x-auto',
          'X-Bz-File-Name': "#{file_path}",
          'X-Bz-Content-Sha1': Digest::SHA1.hexdigest(content)
        }
      )

      if response.json['fileId'] == nil
        raise Fog::Errors::Error, "Failed put_object, status = #{response.status} #{response.body}"
      end

      response.json
    end

    def get_download_url(bucket_name, file_path)
      "#{auth_response['downloadUrl']}/file/#{bucket_name}/#{file_path}"
    end

    def get_object(bucket_name, file_path)
      file_url = get_download_url(bucket_name, file_path)

      result = b2_command(nil,
        method: :get,
        url: file_url
      )

      if result.status == 404
        raise Fog::Errors::NotFound, "Can not find #{file_path.inspect} in bucket #{bucket_name}"
      end

      return result
    end

    def b2_command(command, options = {})
      auth_response = self.auth_response
      options[:headers] ||= {}
      options[:headers]['Authorization'] ||= auth_response['authorizationToken']

      if options[:body] && !options[:body].is_a?(String)
        options[:body] = JSON.generate(options[:body])
      end

      request_url = options.delete(:url) || "#{auth_response['apiUrl']}/b2api/v1/#{command}"

      #pp [:b2_command, request_url, options]

      json_req(options.delete(:method) || :post, request_url, options)
    end

    def _get_bucket_id(bucket_name)
      if @options[:b2_bucket_name] == bucket_name && @options[:b2_bucket_id]
        return @options[:b2_bucket_id]
      else
        cached = @token_cache && @token_cache.buckets

        if cached && cached[bucket_name]
          return cached[bucket_name]['bucketId']
        else
          fetched = _cached_buchets_hash(force_fetch: !!cached)
          return fetched[bucket_name] && fetched[bucket_name]['bucketId']
        end
      end
    end

    def _cached_buchets_hash(force_fetch: false)

      if !force_fetch && cached = @token_cache.buckets
        cached
      end

      buckets_hash = {}
      list_buckets.each do |bucket|
        buckets_hash[bucket['bucketName']] = bucket
      end

      @token_cache.buckets = buckets_hash

      buckets_hash
    end

    def auth_response
      #return @auth_response.json if @auth_response

      if cached = @token_cache.auth_response
        logger.info("get token from cache")
        return cached
      end

      @auth_response = json_req(:get, "https://api.backblazeb2.com/b2api/v1/b2_authorize_account",
        headers: {
          "Authorization" => "Basic " + Base64.strict_encode64("#{@options[:b2_account_id]}:#{@options[:b2_account_token]}")
        },
        persistent: false
      )

      if @auth_response.status >= 400
        raise Fog::Errors::Error, "Authentication error: #{@auth_response.json['message']} (status = #{@auth_response.status})\n#{@auth_response.body}"
      end

      @token_cache.auth_response = @auth_response.json

      @auth_response.json
    end

    def json_req(method, url, options = {})
      start_time = Time.now.to_f
      logger.info("Req #{method.to_s.upcase} #{url}")
      logger.debug(options.to_s)

      if !options.has_key?(:persistent) || options[:persistent] == true
        @connections ||= {}
        full_path = [URI.parse(url).request_uri, URI.parse(url).fragment].compact.join("#")
        host_url = url.sub(full_path, "")
        connection = @connections[host_url] ||= Excon.new(host_url, persistent: true)
        http_response = connection.send(method, options.merge(path: full_path, idempotent: true))
      else
        http_response = Excon.send(method, url, options)
      end

      def http_response.json
        @json ||= JSON.parse(body)
      end

      http_response
    ensure
      status = http_response && http_response.status
      logger.info("Done #{method.to_s.upcase} #{url} = #{status} (#{(Time.now.to_f - start_time).round(3)} sec)")
      logger.debug(http_response.body) if http_response
    end

    def reset_token_cache
      @token_cache.reset
    end
  end
end

