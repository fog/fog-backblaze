require_relative "../test_helper"

describe "list_objects" do
  it "list files in a bucket" do
    content = "az" * 10
    test_file = "test-list_objects"
    CONNECTION.put_object(TEST_BUCKET, test_file, content)

    response = CONNECTION.list_objects(TEST_BUCKET, prefix: test_file)

    # make sure it filter by name prefix
    assert(response.json['files'].all? {|f| f['fileName'].start_with?(test_file) })

    file = response.json['files'].find {|f| f['fileName'] == test_file }

    assert_equal(file['fileName'], test_file)
    assert_equal(file['contentLength'], 20)
  end
end
