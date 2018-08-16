require_relative "../test_helper"

describe "update_bucket" do
  before do
    skip "require full access" unless CONNECTION.options[:b2_account_token]
  end

  it "should update bucket fields" do
    new_val = Time.now.to_i.to_s(36)
    response = CONNECTION.update_bucket(TEST_BUCKET, bucketInfo: {foo: new_val})

    assert_equal(response.status, 200)

    response = CONNECTION.get_bucket(TEST_BUCKET)

    assert_equal(response.body['bucketInfo'], {"foo" => new_val})
  end
end
