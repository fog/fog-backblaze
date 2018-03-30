class Fog::Storage::Backblaze::Mock
  def self.data
    @data ||= Hash.new do |hash, key|
      hash[key] = {}
    end
  end

  def self.reset
    @data = nil
  end

  def initialize(options={})
    @b2_account_id = options[:b2_account_id]
    @b2_account_token = options[:b2_account_token]
    @path = '/v1/AUTH_1234'
    @containers = {}
  end

  def data
    self.class.data[@softlayer_username]
  end

  def reset_data
    self.class.data.delete(@softlayer_username)
  end

  def change_account(account)
    @original_path ||= @path
    version_string = @original_path.split('/')[1]
    @path = "/#{version_string}/#{account}"
  end

  def reset_account_name
    @path = @original_path
  end
end
