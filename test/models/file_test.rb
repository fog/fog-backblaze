require_relative "../test_helper"

describe "storage/models/file" do

  after do
    if @test_bucket
      @test_bucket.files.each(&:destroy)
    end
  end

  it "should return body object before save" do
    @test_bucket = CONNECTION.directories.get(TEST_BUCKET)

    file_io = File.open(__FILE__)
    file = @test_bucket.files.new(key: 'spec', body: file_io)

    assert_equal(file.body, file_io)
  end

  it "should fetch body on demand" do
    @test_bucket = CONNECTION.directories.get(TEST_BUCKET)

    file_io = File.open(__FILE__)
    file = @test_bucket.files.create(key: 'spec', body: file_io)

    file_content = file_io.tap(&:rewind).read

    assert_equal(file.body, file_content)
    assert_equal(@test_bucket.files.new(key: 'spec').body, file_content)
  end

end
