class Fog::Backblaze::Storage::Real
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
    elsif options[:token_cache].is_a?(Fog::Backblaze::TokenCache)
      options[:token_cache]
    else
      Fog::Backblaze::TokenCache::FileTokenCache.new(options[:token_cache])
    end
  end

  def logger
    @logger
  end

  ## Buckets

  # call b2_create_bucket
  def put_bucket(bucket_name, extra_options = {})
    options = {
      accountId: b2_account_id,
      bucketType: extra_options.delete(:public) ? 'allPublic' : 'allPrivate',
      bucketName: bucket_name,
    }.merge(extra_options)

    response = b2_command(:b2_create_bucket, body: options)

    if response.status >= 400
      raise Fog::Errors::Error, "Failed put_bucket, status = #{response.status} #{response.body}"
    end

    if cached = @token_cache.buckets
      @token_cache.buckets = cached.merge(bucket_name => response.json)
    else
      @token_cache.buckets = {bucket_name => response.json}
    end

    response
  end

  # call b2_update_bucket
  # if options[:bucketId] presents, then bucket_name is option
  def update_bucket(bucket_name, extra_options)
    options = {
      accountId: b2_account_id,
      bucketId: extra_options[:bucketId] || _get_bucket_id!(bucket_name),
    }
    if extra_options.has_key?(:public)
      options[:bucketType] = extra_options.delete(:public) ? 'allPublic' : 'allPrivate'
    end
    options.merge!(extra_options)

    response = b2_command(:b2_update_bucket, body: options)

    if response.status >= 400
      raise Fog::Errors::Error, "Failed update_bucket, status = #{response.status} #{response.body}"
    end

    if cached = @token_cache.buckets
      @token_cache.buckets = cached.merge(bucket_name => response.json)
    else
      @token_cache.buckets = {bucket_name => response.json}
    end

    response
  end

  # call b2_list_buckets
  def list_buckets(options = {})
    response = b2_command(:b2_list_buckets, body: {
      accountId: b2_account_id
    }.merge(options))

    response
  end

  # call b2_list_buckets
  def get_bucket(bucket_name)
    response = list_buckets(bucketName: bucket_name)

    bucket = response.json['buckets'].detect do |bucket|
      bucket['bucketName'] == bucket_name
    end

    unless bucket
      raise Fog::Errors::NotFound, "No bucket with name: #{bucket_name}"
    end

    response.body = bucket
    response.json = bucket
    return response
  end

  # call b2_delete_bucket
  def delete_bucket(bucket_name, options = {})
    bucket_id = _get_bucket_id!(bucket_name)

    response = b2_command(:b2_delete_bucket,
      body: {
        bucketId: bucket_id,
        accountId: b2_account_id
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
      #cached.delete(bucket_name)
      #@token_cache.buckets = cached
      @token_cache.buckets = nil
    end

    response
  end

  ## Objects

  # call b2_copy_file
  def copy_object(source_bucket_name, source_object_name, target_bucket_name, target_object_name, options = {})
    file_id = _get_object_version_ids(source_bucket_name, source_object_name)[0]
    response = b2_command(
      'b2_copy_file',
      body: {
        sourceFileId: file_id,
        destinationBucketId: _get_bucket_id(target_bucket_name),
        fileName: target_object_name
      }
    )

    response
  end

  # call b2_list_file_names
  def list_objects(bucket_name, options = {})
    bucket_id = _get_bucket_id!(bucket_name)

    b2_command(:b2_list_file_names, body: {
      bucketId: bucket_id,
      maxFileCount: 10_000
    }.merge(options))
  end

  def head_object(bucket_name, file_path, options = {})
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

  # call b2_get_upload_url
  #
  #   connection.put_object("a-bucket", "/some_file.txt", string_or_io, options)
  #
  # Possible options:
  # * content_type
  # * last_modified - time object or number of miliseconds
  # * content_disposition
  # * extra_headers - hash, list of custom headers
  def put_object(bucket_name, file_path, content, options = {})
    upload_url = @token_cache.fetch("upload_url/#{bucket_name}") do
      bucket_id = _get_bucket_id!(bucket_name)
      result = b2_command(:b2_get_upload_url, body: {bucketId: bucket_id})
      result.json
    end

    if content.is_a?(IO)
      content = content.read
    end

    extra_headers = {}
    if options[:content_type]
      extra_headers['Content-Type'] = options[:content_type]
    end

    if options[:last_modified]
      value = if options[:last_modified].is_a?(::Time)
        (options[:last_modified].to_f * 1000).round
      else
        value
      end
      extra_headers['X-Bz-Info-src_last_modified_millis'] = value
    end

    if options[:content_disposition]
      extra_headers['X-Bz-Info-b2-content-disposition'] = options[:content_disposition]
    end

    if options[:extra_headers]
      options[:extra_headers].each do |key, value|
        extra_headers["X-Bz-Info-#{key}"] = value
      end
    end

    response = b2_command(nil,
      url: upload_url['uploadUrl'],
      body: content,
      headers: {
        'Authorization': upload_url['authorizationToken'],
        'Content-Type': 'b2/x-auto',
        'X-Bz-File-Name': "#{b2_url_encode(file_path)}",
        'X-Bz-Content-Sha1': Digest::SHA1.hexdigest(content)
      }.merge(extra_headers)
    )

    if response.json['fileId'] == nil
      raise Fog::Errors::Error, "Failed put_object, status = #{response.status} #{response.body}"
    end

    response
  end

  # generates url regardless if bucket is private or not
  def get_object_url(bucket_name, file_path)
    "#{auth_response['downloadUrl']}/file/#{b2_url_encode(bucket_name)}/#{b2_url_encode(file_path)}"
  end

  alias_method :get_object_https_url, :get_object_url

  # call b2_get_download_authorization
  def get_public_object_url(bucket_name, file_path, options = {})
    bucket_id = _get_bucket_id!(bucket_name)

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

    response = b2_command(nil,
      method: :get,
      url: file_url
    )

    if response.status == 404
      raise Fog::Errors::NotFound, "Can not find #{file_name.inspect} in bucket #{bucket_name}"
    end

    if response.status > 400
      raise Fog::Errors::Error, "Failed get_object, status = #{response.status} #{response.body}"
    end

    return response
  end

  # call b2_delete_file_version
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

  # TODO TEST
  # call b2_create_key
  def create_key(name, capabilities: nil, bucket_id: nil, name_prefix: nil)
    capabilities ||= [
      'listKeys',
      'writeKeys',
      'deleteKeys',
      'listBuckets',
      'writeBuckets',
      'deleteBuckets',
      'listFiles',
      'readFiles',
      'shareFiles',
      'writeFiles',
      'deleteFiles'
    ]

    response = b2_command(:b2_create_key,
      body: {
        accountId: b2_account_id,
        keyName: name,
        capabilities: capabilities,
        bucketId: bucket_id,
        namePrefix: name_prefix
      }
    )
  end

  # call b2_list_keys
  def list_keys
    response = b2_command(:b2_list_keys,
      body: {
        accountId: b2_account_id,
        maxKeyCount: 1000
      }
    )

    if response.status > 400
      raise Fog::Errors::Error, "Failed get_object, status = #{response.status} #{response.body}"
    end

    response
  end

  def _get_object_version_ids(bucket_name, file_name)
    response = b2_command(:b2_list_file_versions,
      body: {
        startFileName: file_name,
        prefix: file_name,
        bucketId: _get_bucket_id!(bucket_name),
        maxFileCount: 1000
      }
    )

    if response.status >= 400
      raise Fog::Errors::Error, "Fetch error: #{response.json['message']} (status = #{response.status})"
    end

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

  def _get_bucket_id!(bucket_name)
    bucket_id = _get_bucket_id(bucket_name)
    unless bucket_id
      raise Fog::Errors::NotFound, "Can not find bucket \"#{bucket_name}\""
    end

    return bucket_id
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

    auth_string = if @options[:b2_account_id] && @options[:b2_account_token]
      "#{@options[:b2_account_id]}:#{@options[:b2_account_token]}"
    elsif @options[:b2_key_id] && @options[:b2_key_token]
      "#{@options[:b2_key_id]}:#{@options[:b2_key_token]}"
    else
      raise Fog::Errors::Error, "B2 credentials are required, "\
                                "please use b2_account_id and b2_account_token or "\
                                "b2_key_id and b2_key_token"
    end

    @auth_response = json_req(:get, "https://api.backblazeb2.com/b2api/v1/b2_authorize_account",
      headers: {
        "Authorization" => "Basic " + Base64.strict_encode64(auth_string)
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
      options[:body] = ::JSON.generate(options[:body])
    end

    request_url = options.delete(:url) || "#{auth_response['apiUrl']}/b2api/v1/#{command}"

    #pp [:b2_command, request_url, options]

    json_req(options.delete(:method) || :post, request_url, options)
  end

  def json_req(method, url, options = {})
    start_time = Time.now.to_f
    logger.info("Req #{method.to_s.upcase} #{url}")
    if options[:body] && options[:body].size > 300
      logger.debug(options.merge(body: "-- Body #{options[:body].size} bytes --").to_s)
    else
      logger.debug(options.to_s)
    end

    if !options.has_key?(:persistent) || options[:persistent] == true
      @connections ||= {}
      full_path = [URI.parse(url).request_uri, URI.parse(url).fragment].compact.join("#")
      host_url = url.sub(full_path, "")
      connection = @connections[host_url] ||= Excon.new(host_url, persistent: true)
      http_response = connection.send(method, options.merge(path: full_path, idempotent: true))
    else
      http_response = Excon.send(method, url, options)
    end

    http_response.extend(Fog::Backblaze::JSONResponse)
    if http_response.json_response? && http_response.body.size > 0
      http_response.assign_json_body!
    end

    http_response
  ensure
    status = http_response && http_response.status
    logger.info("    Done #{method.to_s.upcase} #{url} = #{status} (#{(Time.now.to_f - start_time).round(3)} sec)")
    if http_response
      logger.debug("    Headers: #{http_response.headers}")
      if method != :head && http_response.headers['Content-Type'].to_s !~ %r{^image/}
        logger.debug("    Body: #{http_response.body}")
      end
    end
  end

  def reset_token_cache
    @token_cache.reset
  end

  # ref: https://www.backblaze.com/b2/docs/string_encoding.html
  def b2_url_encode(str)
    URI.encode_www_form_component(str.force_encoding(Encoding::UTF_8)).gsub("%2F", "/")
  end

  # return @options[:b2_account_id] or call b2_authorize_account when using application key
  def b2_account_id
    return @options[:b2_account_id] if @options[:b2_account_id]
    auth_response['accountId']
  end
end
