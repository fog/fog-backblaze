require_relative "../test_helper"

describe "get_public_object_url" do
  it "should obrain download url" do
    content = Time.now.to_s
    file = "test-get_public_object_url"

    CONNECTION.put_object(TEST_BUCKET, file, content)

    url = CONNECTION.get_public_object_url(TEST_BUCKET, file)

    assert_match(%r{https://f\d\d\d.backblazeb2.com/file/#{TEST_BUCKET}/#{file}?.+}, url)

    assert_equal(Excon.get(url).body, content)
  end
end
