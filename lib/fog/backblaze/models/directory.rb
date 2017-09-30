class Fog::Storage::Backblaze::Directory < Fog::Model
  identity :key, aliases: %w(bucketName)

  attribute :bucket_id, aliases: 'bucketId'
  attribute :bucket_info, aliases: 'bucketInfo'
  attribute :bucket_type, aliases: 'bucketType'


  def save
    requires :key
    options = {}
    #options["predefinedAcl"] = @acl if @acl
    #options["LocationConstraint"] = @location if @location
    #options["StorageClass"] = attributes[:storage_class] if attributes[:storage_class]
    service.put_bucket(key, options)
    true
  end

end
