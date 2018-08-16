require_relative "../test_helper"

describe "get_bucket" do
  before do
    skip "require full access" unless CONNECTION.options[:b2_account_token]
  end

  it "should give buckets info" do
    response = CONNECTION.get_bucket(TEST_BUCKET)

    assert(response.is_a?(Excon::Response))
    assert_equal(response.body['bucketName'], TEST_BUCKET)
  end

  it "should raise eror when no bucket" do
    error = assert_raises { CONNECTION.get_bucket(Time.now.to_i.to_s) }

    assert_equal(error.class, Fog::Errors::NotFound)
    assert_match(/^No bucket with name: \d+/, error.message)
  end
end
