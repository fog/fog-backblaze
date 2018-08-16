require_relative "../test_helper"

describe "list_buckets" do
  it "should give list of buckets" do
    response = CONNECTION.list_buckets

    assert(response.is_a?(Excon::Response))
    assert(response.body['buckets'].detect {|b| b['bucketName'] == TEST_BUCKET})
  end
end
