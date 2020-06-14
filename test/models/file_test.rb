require_relative "../test_helper"

describe "storage/models/file" do

  before do
    @test_file = "spec-#{rand.to_s.sub('.', '')}"
    @test_bucket = CONNECTION.directories.get(TEST_BUCKET)
  end

  after do
    if @test_file
      CONNECTION.delete_object(TEST_BUCKET, @test_file) rescue nil
    end
  end

  it "should return body object before save" do
    file_io = File.open(__FILE__)
    file = @test_bucket.files.new(key: @test_file, body: file_io)

    assert_equal(file.body, file_io)
  end

  it "should fetch body on demand" do
    file_io = File.open(__FILE__)
    file = @test_bucket.files.create(key: @test_file, body: file_io)

    file_content = file_io.tap(&:rewind).read

    assert_equal(file.body, file_content)
    assert_equal(@test_bucket.files.new(key: @test_file).body, file_content)
  end

end
