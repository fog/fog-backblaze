class Fog::Backblaze::Storage::File < Fog::Model

  identity :file_name, aliases: %w{fileName key name}

  attribute :content_length, aliases: 'contentLength', :type => :integer
  attribute :content_type, aliases: 'contentType'
  attribute :file_id, aliases: 'fileId'
  attribute :file_info, aliases: 'fileInfo'
  attribute :upload_timestamp, aliases: 'uploadTimestamp'

  attr_accessor :directory

  alias_method :name, :file_name

  # TODO: read content from cloud on demand
  def body
    attributes[:body] #||= file_id && (file = collection.get(identity)) ? file.body : ""
  end

  def body=(new_body)
    attributes[:body] = new_body
  end

  alias_method :key, :file_name
  alias_method :key=, :file_name=

  def save(options = {})
    requires :body, :directory, :key

    options[:content_type] = content_type if content_type

    data = service.put_object(directory.key, key, body, options)

    merge_attributes(data.headers.reject { |key, _value| %w(contentLength contentType).include?(key) })

    self.content_length = Fog::Storage.get_body_size(body)
    self.content_type ||= Fog::Storage.get_content_type(body)

    true
  end

  def destroy
    requires :key
    response = service.delete_object(directory.key, key)
    return true if response.nil?
    return response.status < 400
  #rescue Fog::Errors::NotFound
  #  false
  end

  def public_url
    requires :directory, :key

    service.get_object_url(directory.key, key)
  end

  def url attr
    requires :directory, :key
    service.get_public_object_url(directory.key, key, {})
  end

end
