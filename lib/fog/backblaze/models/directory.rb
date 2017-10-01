class Fog::Storage::Backblaze::Directory < Fog::Model
  identity :key, aliases: %w(bucketName)

  attribute :bucket_id, aliases: 'bucketId'
  attribute :bucket_info, aliases: 'bucketInfo'
  attribute :bucket_type, aliases: 'bucketType'

  def destroy
    requires :key
    service.delete_bucket(key)
    true
  #rescue Fog::Errors::NotFound
  #  false
  end

  def save
    requires :key
    options = {}

    response = service.put_bucket(key, options)

    attributes[:bucket_id] = response.json['bucketId']
    attributes[:bucket_type] = response.json['bucketType']
    attributes[:bucket_info] = response.json['bucketInfo']

    true
  end

  def files
    @files ||= Fog::Storage::Backblaze::Files.new(directory: self, service: service)
  end

  def public?
    attributes[:bucket_type] == "allPublic"
  end

end
