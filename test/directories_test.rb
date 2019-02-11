require_relative "test_helper"

describe "directories" do

  it "should give list" do
    result = CONNECTION.directories

    assert_equal(result.class, Fog::Backblaze::Storage::Directories)

    test_bucket = result.detect {|bucket| bucket.key == TEST_BUCKET }
    assert_equal(test_bucket.bucket_type, "allPrivate")
    assert_equal(test_bucket.bucket_id, "2ee4e458c4bbd48855e60c1c")
  end

end
