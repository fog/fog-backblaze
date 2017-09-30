class Fog::Storage::Backblaze::Directories < Fog::Collection
  model Fog::Storage::Backblaze::Directory

  def all
    data = service.list_buckets
    load(data)
  end

  def get(name)
    bucket = service.list_buckets.detect {|bucket| bucket['bucketName'] == name }
    return new(bucket) if bucket
  end

end