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

```ruby
require_relative "lib/fog/backblaze"

connection = Fog::Storage.new(
  provider: 'backblaze',
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

  # "token_cache" is a place to temporary store access token (valid for 24 hours) and some other value
  # use  nil for memory storage (default)
  # false to disable
  # string for file
  # Fog::Backblaze::TokenCache instance for custom cache storage
  token_cache: 'file.txt'
)
```
