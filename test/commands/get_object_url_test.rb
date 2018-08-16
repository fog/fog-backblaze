require_relative "../test_helper"

describe "get_object_url" do
  it "should generate download url" do
    content = Time.now.to_s
    CONNECTION.put_object(TEST_BUCKET, "test-get_object_url", content)

    url = CONNECTION.get_object_url(TEST_BUCKET, "test-get_object_url")

    assert_match(%r{https://f\d\d\d.backblazeb2.com/file/#{TEST_BUCKET}/test-get_object_url}, url)

    assert_equal(
      CONNECTION.get_object_url(TEST_BUCKET, "test-get_object_url"),
      CONNECTION.get_object_https_url(TEST_BUCKET, "test-get_object_url")
    )
  end
end
