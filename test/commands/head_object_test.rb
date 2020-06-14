require_relative "../test_helper"

describe "head_object" do

  it "should raise erorr when not found" do
    error = assert_raises do
      CONNECTION.head_object(TEST_BUCKET, "something/not/real")
    end

    assert_equal(error.class, Fog::Errors::NotFound)
    assert_equal(error.message, %{Can not find "something/not/real" in bucket #{TEST_BUCKET}})
  end

  it "should give project headers" do
    content = Time.now.to_s
    filename = "test-head_object-#{rand.to_s.sub(".", '')}.csv"
    CONNECTION.put_object(TEST_BUCKET, filename, content)

    response = CONNECTION.head_object(TEST_BUCKET, filename)

    assert_equal(response.headers['x-bz-file-name'], filename)
    assert_equal(response.headers['x-bz-content-sha1'], Digest::SHA1.hexdigest(content))
    assert_equal(response.headers['Content-Type'], "text/csv")
    assert_equal(response.headers['Content-Length'], content.size.to_s)

    assert_equal(response.body, "")
  end

end
