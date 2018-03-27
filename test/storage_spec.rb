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

  it "should upload binary file correctly" do
    content = File.open('test/pic.jpg', 'rb', &:read)
    response = CONNECTION.put_object(TEST_BUCKET, "pic.jpg", content)

    response = CONNECTION.get_object(TEST_BUCKET, "pic.jpg")
    assert_equal(response.body, content)
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

  it "should give project headers" do
    content = Time.now.to_s
    CONNECTION.put_object(TEST_BUCKET, "test-head_object.csv", content)

    response = CONNECTION.head_object(TEST_BUCKET, "test-head_object.csv")

    assert_equal(response.headers['x-bz-file-name'], "test-head_object.csv")
    assert_equal(response.headers['x-bz-content-sha1'], Digest::SHA1.hexdigest(content))
    assert_equal(response.headers['Content-Type'], "text/csv")
    assert_equal(response.headers['Content-Length'], content.size.to_s)

    assert_equal(response.body, "")
  end

end

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

describe "_get_bucket_id" do
  it "should check b2_bucket_name and b2_bucket_id" do
    connection = Fog::Storage.new(
      provider: 'backblaze',
      b2_account_id: '123',
      b2_account_token: '123',
      logger: CONNECTION.logger,
      b2_bucket_name: 'test-auth-bucket',
      b2_bucket_id: 'configured_bucket_id'
    )

    assert_equal(connection._get_bucket_id(connection.options[:b2_bucket_name]), connection.options[:b2_bucket_id])
  end

  it "should return nil when bucket not found" do
    #CONNECTION.token_cache.buckets = {}
    result = CONNECTION._get_bucket_id(Time.now.to_i.to_s)
    assert_nil(result)
  end
end

describe "list_buckets" do
  it "should give list of buckets" do
    response = CONNECTION.list_buckets

    assert(response.is_a?(Excon::Response))
    assert(response.body['buckets'].detect {|b| b['bucketName'] == TEST_BUCKET})
  end
end

describe "get_bucket" do
  it "should give buckets info" do
    response = CONNECTION.get_bucket(TEST_BUCKET)

    assert(response.is_a?(Excon::Response))
    assert_equal(response.body['bucketName'], TEST_BUCKET)
  end

  it "should raise eror when no bucket" do
    error = assert_raises { CONNECTION.get_bucket(Time.now.to_i.to_s) }

    assert_equal(error.class, Fog::Errors::NotFound)
    assert_match(/^No bucket with name: \d+, found: .+/, error.message)
  end
end

describe "put_bucket & delete_bucket" do
  it "should delete create and bucket" do
    tmp_name = "gog-test-#{Time.now.to_i.to_s(36)}"
    CONNECTION.put_bucket(tmp_name)
    response = CONNECTION.delete_bucket(tmp_name)

    assert(response.json['bucketName'], tmp_name)

    error = assert_raises { CONNECTION.get_bucket(tmp_name) }

    assert_equal(error.class, Fog::Errors::NotFound)
  end
end
