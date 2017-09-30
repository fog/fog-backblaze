require_relative "test_helper"

describe "auth_response" do
  it "should raise error with invalid credentials" do
    connection = Fog::Storage.new(
      provider: 'backblaze',
      b2_account_id: '123',
      b2_account_token: '123',
      logger: CONNECTION.logger
    )

    error = assert_raises do
      connection.auth_response
    end

    assert_equal(error.class, Fog::Errors::Error)
    assert_includes(error.message, "Authentication error: Invalid authorization token (status = 401)")
  end

  # TODO: solve sometimes failing
  it "should give auth credentials" do
    CONNECTION.reset_token_cache
    assert_nil(CONNECTION.token_cache.auth_response)

    response = CONNECTION.auth_response

    assert(response['authorizationToken'] =~ /.+/)
    assert(response['apiUrl'] =~ /.+/)
    assert(response['downloadUrl'] =~ /.+/)

    # make sure it's saved in cache
    assert_equal(CONNECTION.token_cache.auth_response, response)
    assert_equal(CONNECTION.auth_response, response)
  end
end

describe "put_object" do
  it "should create file" do
    content = Time.now.to_s
    response = CONNECTION.put_object(TEST_BUCKET, "test-put_object", content)

    assert_equal(response['action'], 'upload')
    assert_equal(response['contentLength'], content.size)
    assert(response['fileId'] =~ /.+/)
    assert_in_delta(response['uploadTimestamp'], Time.now.to_i * 1000, 100_000)
  end

  it "should raise error when name is invalid" do
    error = assert_raises do
      CONNECTION.put_object(TEST_BUCKET, "test-put_object%", "aaa")
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
end

describe "get_object" do

  it "should get object content" do
    content = Time.now.to_s
    CONNECTION.put_object(TEST_BUCKET, "test-get_object", content)

    response = CONNECTION.get_object(TEST_BUCKET, "test-get_object")

    assert_equal(response.body, content)
    assert_equal(response.headers['x-bz-file-name'], 'test-get_object')
  end

end

describe "head_object" do

  it "should raise erorr when not found" do
    error = assert_raises do
      CONNECTION.head_object(TEST_BUCKET, "something/not/real")
    end

    assert_equal(error.class, Fog::Errors::NotFound)
    assert_equal(error.message, %{Can not find "something/not/real" in bucket #{TEST_BUCKET}})
  end

end
