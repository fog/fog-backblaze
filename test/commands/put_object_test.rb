require_relative "../test_helper"

describe "put_object" do
  it "should create file" do
    content = Time.now.to_s
    response = CONNECTION.put_object(TEST_BUCKET, "test-put_object", content).json

    assert_equal(response['action'], 'upload')
    assert_equal(response['contentLength'], content.size)
    assert(response['fileId'] =~ /.+/)
    assert_in_delta(response['uploadTimestamp'], Time.now.to_i * 1000, 100_000)
  end

  it "should raise error when name is invalid" do
    error = assert_raises do
      CONNECTION.put_object(TEST_BUCKET, "test-put_object" * 70, "aaa")
    end

    assert_equal(error.class, Fog::Errors::Error)
    assert_includes(error.message, "Failed put_object, status = 400")
  end

  it "should raise when bicket not found" do
    error = assert_raises do
      CONNECTION.put_object('aaa', "test-put_object", "aaa")
    end

    assert_equal(error.class, Fog::Errors::NotFound)
    assert_equal(error.message, %{Can not find bucket "aaa"})
  end

  it "should upload binary file correctly" do
    content = File.open('test/pic.jpg', 'rb', &:read)
    response = CONNECTION.put_object(TEST_BUCKET, "pic.jpg", content)

    response = CONNECTION.get_object(TEST_BUCKET, "pic.jpg")
    assert_equal(response.body, content)
  end
end
