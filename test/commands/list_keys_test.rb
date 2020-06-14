require_relative "../test_helper"

describe "list_keys" do
  before do
    skip "require full access" unless CONNECTION.options[:b2_account_token]
  end

  it "should list api keys in account" do
    keys = CONNECTION.list_keys
    current_key = keys.json['keys'].detect {|key| key['applicationKeyId'] == B2_CREDENTIALS['key_id']}

    assert_equal(current_key['keyName'], 'fog-test')
    assert_equal(current_key['capabilities'], %w{
      listBuckets
      listFiles
      readFiles
      shareFiles
      writeFiles
      deleteFiles
    })
  end
end
