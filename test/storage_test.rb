require_relative "test_helper"

describe "_get_bucket_id" do
  it "should check b2_bucket_name and b2_bucket_id" do
    connection = Fog::Storage.new(
      provider: 'backblaze',
      b2_account_id: '123',
      b2_account_token: '123',
      logger: CONNECTION.logger,
      b2_bucket_name: 'test-auth-bucket',
      b2_bucket_id: 'configured_bucket_id'
    )

    assert_equal(connection._get_bucket_id(connection.options[:b2_bucket_name]), connection.options[:b2_bucket_id])
  end

  it "should return nil when bucket not found" do
    #CONNECTION.token_cache.buckets = {}
    result = CONNECTION._get_bucket_id(Time.now.to_i.to_s)
    assert_nil(result)
  end
end