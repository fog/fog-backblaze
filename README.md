# Fog::Backblaze

Integration library for gem fog and [Backblaze B2 Cloud Storage](https://www.backblaze.com/b2/cloud-storage.html)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fog-backblaze'
```

Or install it with gem:

```sh
gem install fog-backblaze
```

## Usage

#### With CarrierWave

```ruby
CarrierWave.configure do |config|
  config.fog_credentials = {
    provider: 'backblaze',
    b2_key_id: 'xxxx',
    b2_key_token: 'zzzxxxccc'
  }
  config.fog_directory = 'my-b2-bucket-name'
  config.fog_public = true
end
```
For now only public buckets are supported with CarrierWave

#### With fog library

```ruby
require "fog/backblaze"

connection = Fog::Storage.new(
  provider: 'backblaze',

  # with one key (more secure)
  # get your API keys at https://secure.backblaze.com/app_keys.htm
  b2_key_id: 'xxxx',
  b2_key_token: 'zzzxxxccc'

  # full access to b2 account (less secure)
  b2_account_id: '123456',
  b2_account_token: 'aaaaabbbbbccccddddeeeeeffffff111112222223333',

  # optional, used to make some operations faster
  b2_bucket_name: 'app-test',
  b2_bucket_id: '6ec42006ec42006ec42',

  logger: Logger.new(STDOUT).tap {|l|
    l.formatter = proc {|severity, datetime, progname, msg|
      "#{severity.to_s[0]} - #{datetime.strftime("%T.%L")}: #{msg}\n"
    }
  },

  token_cache: 'file.txt'
)
```

#### Create bucket

```ruby
connection.directories.create(key: 'my-b2-bucket', public: true)
# or
connection.put_bucket("my-b2-bucket", public: true)
```

#### Get Bucket

```ruby
bucket = connection.directories.get('my-b2-bucket')
bucket.name # => 'my-b2-bucket'
bucket.bucket_id # => "2ee4e45855e60c1c8c4bbd48"
bucket.bucket_type # => "allPrivate"
bucket.cors_rules # => []
```

#### Delete bucket

```ruby
connection.directories.new(key: 'my-b2-bucket').destroy
# or
connection.delete_bucket("my-b2-bucket")
```

#### Upload File

```ruby
file = directory.files.create(
  key: 'example.html',
  body: File.open(__FILE__)
)
# or
connection.put_object("my-b2-bucket", "example.html", File.open(__FILE__))
```

#### List Files

```ruby
directory.files.each do |file|
  p [directory.name, file.name]
end
# or
connection.list_objects("my-b2-bucket").json['files'] do |file_hash|
  p ["my-b2-bucket", file_hash['fileName']]
end
```

#### Read File
```ruby
directory.files.new(key: 'example.html').body
# or
connection.get_object("my-b2-bucket", "example.html")
```

#### Get public URL
```ruby
connection.get_public_object_url("my-b2-bucket", "example.html")
```

#### Delete File

```ruby
directory.files.new(key: 'example.html').destroy
# or
connection.delete_object("my-b2-bucket", "example.html")
```

See [example](examples/example.rb) for more details

## Adding b2_bucket_id

Most of internal operations requires `bucketId` field, to get right value, fog-backblaze will make API request.
Usually applications use only one bucket and it's id never change (it may change only if we delete bucket and create new one with same name).
We can eliminate this API request by setting `b2_bucket_id` attribute.

How to get `b2_bucket_id`:
```ruby
p connection._get_bucket_id(bucket_name)
```

## Token Cache

Each request requires authentication token, it comes from `b2_authorize_account` response.

Let's say we want to upload a files, then it will make 4 requests inernally:

1. `b2_authorize_account` - valid for 24 hours
2. `b2_list_buckets` - to get bucket_id value can be optimized with `:b2_bucket_id` field (should not change)
3. `b2_get_upload_url` - valid for 24 hours
4. Send data to URL from step 3

Results of steps 1, 2, 3 can be re-used by saving in TokenCache. It acts as general cachin interface with few predefined implementations:

* In memory store `token_cache: :memory` (default)
* JSON file store `token_cache: 'file.txt'`
* Null store (will not cache anything) `token_cache: false` or `token_cache: Fog::Backblaze::TokenCache::NullTokenCache.new`
* Create your custom, see [token_cache.rb](lib/fog/backblaze/token_cache.rb) for examples
