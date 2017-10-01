class Fog::Storage::Backblaze::File < Fog::Model

  identity :file_name, aliases: 'fileName'

  attribute :content_length, aliases: 'contentLength'
  attribute :content_type, aliases: 'contentType'
  attribute :file_id, aliases: 'fileId'
  attribute :file_info, aliases: 'fileInfo'
  attribute :upload_timestamp, aliases: 'uploadTimestamp'

  attr_writer :body

end
