require_relative "../test_helper"

describe "copy_object" do

  after do
    if @new_file
      CONNECTION.delete_object(TEST_BUCKET, @new_file)
    end
    if @copied_file
      CONNECTION.delete_object(TEST_BUCKET, @copied_file)
    end
  end

  it "should copy object content" do
    content = Time.now.to_s
    prefix = rand.to_s.sub('.', '')
    @new_file = "#{prefix}-test-copy_object-original"
    @copied_file = "#{prefix}-test-copy_object-copy"

    CONNECTION.put_object(TEST_BUCKET, @new_file, content)

    CONNECTION.copy_object(
      source_bucket: TEST_BUCKET,
      source_object: @new_file,
      target_bucket: TEST_BUCKET,
      target_object: @copied_file
    )

    downloaded_copy = CONNECTION.get_object(TEST_BUCKET, @copied_file)

    assert_equal(downloaded_copy.body, content)
  end

  it "should raise error when not :bucket argument passed" do
    error = assert_raises do
      CONNECTION.copy_object(source_object: 'a', target_object: 'a')
    end

    assert_equal(error.class, ArgumentError)
    assert_equal(error.message, "arguemnt bucket either source_bucket is required for copy_object()")
  end

  it "should raise error when not :bucket argument passed" do
    error = assert_raises do
      res = CONNECTION.copy_object(
        bucket: TEST_BUCKET,
        source_object: 'aaa1',
        target_object: 'aaa2'
      )
    end

    assert_equal(error.class, Fog::Errors::NotFound)
    assert_equal(error.message, "Command copy_object failed: Can not find source object: aaa1 in bucket #{TEST_BUCKET}")
  end

end
