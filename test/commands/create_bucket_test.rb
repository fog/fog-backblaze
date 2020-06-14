require_relative "../test_helper"

describe "create_bucket" do
  before do
    skip "require full access" unless CONNECTION.options[:b2_account_token]
  end

  after do
    if @bucket_name
      CONNECTION.delete_bucket(@bucket_name) rescue nil
    end
  end

  it "should create a bucket" do
    @bucket_name = "fog-demo-#{rand.to_s.sub('.', '')}"

    res = CONNECTION.put_bucket(@bucket_name)

    assert_equal(res.json['bucketName'], @bucket_name)
    assert_equal(res.json['bucketType'], 'allPrivate')
  end
end
