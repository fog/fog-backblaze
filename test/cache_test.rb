require_relative "test_helper"

class TestTokenCache < Fog::Backblaze::TokenCache; end

describe "cache implementations" do

  it "should set @token_cache = :memory if no token_cache option provided" do
    connection = Fog::Storage.new(
      provider: 'backblaze'
    )

    assert_equal(connection.token_cache.is_a?(Fog::Backblaze::TokenCache), true)
  end

  it "should set @token_cache = :memory if token_cache option is `nil`" do
    connection = Fog::Storage.new(
      provider: 'backblaze',
      token_cache: nil,
    )

    assert_equal(connection.token_cache.is_a?(Fog::Backblaze::TokenCache), true)
  end

  it "should set @token_cache = :memory if token_cache option is `false`" do
    connection = Fog::Storage.new(
      provider: 'backblaze',
      token_cache: false,
    )

    assert_equal(connection.token_cache.is_a?(Fog::Backblaze::TokenCache::NullTokenCache), true)
  end

  it "should set @token_cache = <provided token cache> if token_cache option is a `Fog::Backblaze::TokenCache`" do
    cache = TestTokenCache.new

    connection = Fog::Storage.new(
      provider: 'backblaze',
      token_cache: cache
    )

    assert_equal(connection.token_cache, cache)
  end

  it "should set @token_cache = Fog::Backblaze::TokenCache::FileTokenCache if token_cache option is a String" do
    connection = Fog::Storage.new(
      provider: 'backblaze',
      token_cache: 'file.txt',
    )

    assert_equal(connection.token_cache.is_a?(Fog::Backblaze::TokenCache::FileTokenCache), true)
    assert_equal(connection.token_cache.instance_variable_get('@file'), 'file.txt')
  end
end
