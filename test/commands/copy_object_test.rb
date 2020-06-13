require_relative "../test_helper"

describe "copy_object" do

  it "should copy object content" do
    content = Time.now.to_s
    original_file = 'test-copy_object-original'
    copied_file = 'test-copy_object-copy'
    CONNECTION.put_object(TEST_BUCKET, original_file, content)

    CONNECTION.copy_object(
      TEST_BUCKET,
      original_file,
      TEST_BUCKET,
      copied_file,
      options = {}
    )

    downloaded_copy = CONNECTION.get_object(TEST_BUCKET, copied_file)

    assert_equal(downloaded_copy.body, content)
  end

end
