require_relative "../test_helper"

describe "get_object" do

  it "should get object content" do
    content = Time.now.to_s
    CONNECTION.put_object(TEST_BUCKET, "test-get_object", content)

    response = CONNECTION.get_object(TEST_BUCKET, "test-get_object")

    assert_equal(response.body, content)
    assert_equal(response.headers['x-bz-file-name'], 'test-get_object')
  end

end
