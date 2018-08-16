require_relative "../test_helper"

describe "put_bucket & delete_bucket" do
  before do
    skip "require full access" unless CONNECTION.options[:b2_account_token]
  end

  it "should delete create and bucket" do
    tmp_name = "gog-test-#{Time.now.to_i.to_s(36)}"
    CONNECTION.put_bucket(tmp_name)
    response = CONNECTION.delete_bucket(tmp_name)

    assert(response.json['bucketName'], tmp_name)

    error = assert_raises { CONNECTION.get_bucket(tmp_name) }

    assert_equal(error.class, Fog::Errors::NotFound)
  end
end
