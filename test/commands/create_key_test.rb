require_relative "../test_helper"

describe "create_key" do
  before do
    skip "require full access" unless CONNECTION.options[:b2_account_token]
  end

  after do
    if @key_name
      CONNECTION.delete_key(@key_name)
    end
  end

  it "should create api key" do
    @key_name = "key-#{rand.to_s.sub('.', '')}"
    new_key = CONNECTION.create_key(@key_name, capabilities: ['listKeys'])

    assert_equal(new_key.json['keyName'], @key_name)
    assert_equal(new_key.json['capabilities'], ['listKeys'])
  end
end
