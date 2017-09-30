require_relative "test_helper"

describe "directories" do

  it "should give list" do
    result = CONNECTION.directories

    assert_equal(result.class, Fog::Storage::Backblaze::Directories)

    test_bucket = result.detect {|bucket| bucket.key == TEST_BUCKET }
    assert_equal(test_bucket.bucket_type, "allPrivate")
  end

end
