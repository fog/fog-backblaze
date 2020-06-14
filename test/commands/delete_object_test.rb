require_relative "../test_helper"

describe "delete_object" do
  it "should obrain download url" do
    content = Time.now.to_s
    file = "test-delete_object-#{rand.to_s.sub(".", '')}"

    CONNECTION.put_object(TEST_BUCKET, file, content)

    response = CONNECTION.head_object(TEST_BUCKET, file)
    assert_equal(response.status, 200)

    CONNECTION.delete_object(TEST_BUCKET, file)

    error = assert_raises do
      CONNECTION.head_object(TEST_BUCKET, file)
    end

    assert_equal(error.class, Fog::Errors::NotFound)
    assert_equal(error.message, %{Can not find "#{file}" in bucket #{TEST_BUCKET}})
  end
end
