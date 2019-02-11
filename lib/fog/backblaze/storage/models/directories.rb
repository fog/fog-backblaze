class Fog::Backblaze::Storage::Directories < Fog::Collection
  model Fog::Backblaze::Storage::Directory

  def all
    data = service.list_buckets
    load(data.body['buckets'])
  end

  def get(name)
    list_response = service.list_buckets
    bucket = list_response.json['buckets'].detect {|bucket| bucket['bucketName'] == name }
    return new(bucket) if bucket
  end

end
