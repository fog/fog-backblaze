require 'json'
require 'digest'
require 'cgi'

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

      @token_cache = if options[:token_cache].nil? || options[:token_cache] == :memory
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

    ## Buckets

    def put_bucket(key, extra_options = {})
      options = {
        accountId: @options[:b2_account_id],
        bucketType: extra_options.delete(:public) ? 'allPublic' : 'allPrivate',
        bucketName: key,
      }.merge(extra_options)

      response = b2_command(:b2_create_bucket, body: options)

      if response.status >= 400
        raise Fog::Errors::Error, "Failed put_bucket, status = #{response.status} #{response.body}"
      end

      if cached = @token_cache.buckets
        @token_cache.buckets = cached.merge(key => response.json)
      else
        @token_cache.buckets = {key => response.json}
      end

      response
    end

    def list_buckets
      response = b2_command(:b2_list_buckets, body: {accountId: @options[:b2_account_id]})

      response
    end

    def get_bucket(bucket_name)
      reponse = list_buckets
      bucket = reponse.json['buckets'].detect do |bucket|
        bucket['bucketName'] == bucket_name
      end

      unless bucket
        raise Fog::Errors::NotFound, "No bucket with name: #{bucket_name}, " +
          "found: #{reponse.json['buckets'].map {|b| b['bucketName']}.join(", ")}"
      end

      reponse.body = bucket
      reponse.json = bucket
      return reponse
    end

    def delete_bucket(bucket_name, options = {})
      bucket_id = _get_bucket_id(bucket_name)

      unless bucket_id
        raise Fog::Errors::NotFound, "Can not bucket #{bucket_name}"
      end

      response = b2_command(:b2_delete_bucket,
        body: {
          bucketId: bucket_id,
          accountId: @options[:b2_account_id]
        }
      )

      if !options[:is_retrying]
        if response.status == 400 && response.json['message'] =~ /Bucket .+ does not exist/
          logger.info("Try drop cache and try again")
          @token_cache.buckets = nil
          return delete_bucket(bucket_name, is_retrying: true)
        end
      end

      if response.status >= 400
        raise Fog::Errors::Error, "Failed delete_bucket, status = #{response.status} #{response.body}"
      end

      if cached = @token_cache.buckets
        cached.delete(bucket_name)
        @token_cache.buckets = cached
      end

      response
    end

    ## Objects

    def list_objects(bucket_name, options = {})
      bucket_id = _get_bucket_id(bucket_name)

      unless bucket_id
        raise Fog::Errors::NotFound, "Can not bucket #{bucket_name}"
      end

      b2_command(:b2_list_file_names, body: {
        bucketId: bucket_id,
        maxFileCount: 10_000
      }.merge(options))
    end

    def head_object(bucket_name, file_path)
      file_url = get_object_url(bucket_name, file_path)

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
          'X-Bz-File-Name': "#{_esc_file(file_path)}",
          'X-Bz-Content-Sha1': Digest::SHA1.hexdigest(content)
        }
      )

      if response.json['fileId'] == nil
        raise Fog::Errors::Error, "Failed put_object, status = #{response.status} #{response.body}"
      end

      response
    end

    def get_object_url(bucket_name, file_path)
      "#{auth_response['downloadUrl']}/file/#{CGI.escape(bucket_name)}/#{_esc_file(file_path)}"
    end

    alias_method :get_object_https_url, :get_object_url

    def get_public_object_url(bucket_name, file_path, options = {})
      bucket_id = _get_bucket_id(bucket_name)

      unless bucket_id
        raise Fog::Errors::NotFound, "Can not bucket #{bucket_name}"
      end

      result = b2_command(:b2_get_download_authorization, body: {
        bucketId: bucket_id,
        fileNamePrefix: file_path,
        validDurationInSeconds: 604800
      }.merge(options))

      if result.status == 404
        raise Fog::Errors::NotFound, "Can not find #{file_path.inspect} in bucket #{bucket_name}"
      end

      if result.status >= 400
        raise Fog::Errors::NotFound, "Backblaze respond with status = #{result.status} - #{result.reason_phrase}"
      end

      "#{get_object_url(bucket_name, file_path)}?Authorization=#{result.json['authorizationToken']}"
    end

    def get_object(bucket_name, file_name)
      file_url = get_object_url(bucket_name, file_name)

      result = b2_command(nil,
        method: :get,
        url: file_url
      )

      if result.status == 404
        raise Fog::Errors::NotFound, "Can not find #{file_name.inspect} in bucket #{bucket_name}"
      end

      return result
    end

    def delete_object(bucket_name, file_name)
      version_ids = _get_object_version_ids(bucket_name, file_name)

      if version_ids.size == 0
        raise Fog::Errors::NotFound, "Can not find #{file_name} in in bucket #{bucket_name}"
      end

      logger.info("Deleting #{version_ids.size} versions of #{file_name}")

      last_response = nil
      version_ids.each do |version_id|
        last_response = b2_command(:b2_delete_file_version, body: {
          fileName: file_name,
          fileId: version_id
        })
      end

      last_response
    end

    def _get_object_version_ids(bucket_name, file_name)
      response = b2_command(:b2_list_file_versions,
        body: {
          startFileName: file_name,
          prefix: file_name,
          bucketId: _get_bucket_id(bucket_name),
          maxFileCount: 1000
        }
      )

      if response.json['files']
        version_ids = []
        response.json['files'].map do |file_version|
          version_ids << file_version['fileId'] if file_version['fileName'] == file_name
        end
        version_ids
      else
        []
      end
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
      list_buckets.json['buckets'].each do |bucket|
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

      http_response.extend(Fog::Backblaze::JSONReponse)
      http_response.assign_json_body! if http_response.josn_response?

      http_response
    ensure
      status = http_response && http_response.status
      logger.info("Done #{method.to_s.upcase} #{url} = #{status} (#{(Time.now.to_f - start_time).round(3)} sec)")
      logger.debug(http_response.headers) if http_response
      logger.debug(http_response.body) if http_response
    end

    def reset_token_cache
      @token_cache.reset
    end

    def _esc_file(file_name)
      CGI.escape(file_name).gsub('%2F', '/')
    end
  end
end

