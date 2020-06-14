class Fog::Backblaze::Storage::Files < Fog::Collection
  model Fog::Backblaze::Storage::File

  attribute :directory
  #attribute :common_prefixes, :aliases => "CommonPrefixes"
  #attribute :delimiter,       :aliases => "Delimiter"
  #attribute :page_token,      :aliases => %w(pageToken page_token)
  #attribute :max_results,     :aliases => ["MaxKeys", "max-keys"]
  #attribute :prefix,          :aliases => "Prefix"

  def all(options = {})
    requires :directory

    body = service.list_objects(directory.key, options).body
    load(body["files"] || [])
  end

  def get(file_name)
    requires :directory

    file_response = service.get_object(directory.key, file_name)
    file_data = _headers_to_attrs(file_response)

    new(file_data)
  end

  def new(attributes = {})
    requires :directory
    super({directory: directory}.merge!(attributes))
  end

  # TODO: download url for private buckets
  def get_https_url(file_name, expires, options = {})
    requires :directory
    service.get_object_https_url(directory.key, file_name, expires, options)
  end

  # TODO: download url for private buckets
  def head_url(file_name, expires, options = {})
    requires :directory
    service.get_object_https_url(directory.key, key, expires, options)
  end

  def head(file_name, options = {})
    requires :directory
    data = service.head_object(directory.key, file_name, options)
    file_data = _headers_to_attrs(data)
    new(file_data)
  rescue Excon::Errors::NotFound
    nil
  end

  def _headers_to_attrs(file_response)
    {
      'fileName'        => file_response.headers['x-bz-file-name'],
      'fileId'          => file_response.headers['x-bz-file-id'],
      'uploadTimestamp' => file_response.headers['X-Bz-Upload-Timestamp'],
      'contentType'     => file_response.headers['Content-Type'],
      'contentLength'   => file_response.headers['Content-Length']
    }
  end

end
