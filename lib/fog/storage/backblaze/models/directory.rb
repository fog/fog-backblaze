class Fog::Storage::Backblaze::Directory < Fog::Model
  identity :key, aliases: %w(bucketName)

  attribute :bucket_id#,       aliases: 'bucketId'
  attribute :bucket_info#,     aliases: 'bucketInfo'
  attribute :bucket_type#,     aliases: 'bucketType'
  attribute :cors_rules#,      aliases: 'corsRules'
  attribute :lifecycle_rules#, aliases: 'lifecycleRules'
  attribute :revision

  alias_method :name, :key

  def destroy
    requires :key
    response = service.delete_bucket(key)
    return response.status < 400
  #rescue Fog::Errors::NotFound
  #  false
  end

  def save
    requires :key
    options = {}

    options[:bucketInfo]     = bucket_info     if bucket_info
    options[:bucketType]     = bucket_type     if bucket_type
    options[:lifecycleRules] = lifecycle_rules if lifecycle_rules
    options[:corsRules]      = cors_rules      if cors_rules

    if attributes[:bucket_id]
      options[:bucketId] = attributes[:bucket_id]
      response = service.update_bucket(key, options)
    else
      response = service.put_bucket(key, options)
    end

    attributes[:bucket_id] = response.json['bucketId']
    attributes[:bucket_type] = response.json['bucketType']
    attributes[:bucket_info] = response.json['bucketInfo']
    attributes[:revision] = response.json['revision']
    attributes[:lifecycle_rules] = response.json['lifecycleRules']
    attributes[:cors_rules] = response.json['corsRules']

    true
  end

  def files
    @files ||= Fog::Storage::Backblaze::Files.new(directory: self, service: service)
  end

  def public?
    attributes[:bucket_type] == "allPublic"
  end

  alias_method :public, :public?

  def public=(value)
    self.bucket_type = value ? 'allPublic' : 'allPrivate'
  end

end
