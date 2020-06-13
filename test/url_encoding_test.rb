require_relative "test_helper"
require 'uri'
require 'json'

describe "Fog::Backblaze::Storage::Real#b2_url_encode" do

  # ref: https://www.backblaze.com/b2/docs/string_encoding.html
  it "should properly URL encode strings according to b2 spec" do
    test_cases = JSON.parse(File.read('b2_url_encoding_test_cases.json'))
    klass = Fog::Backblaze::Storage::Real.new

    test_cases.each do |test_case|
      encoded = klass.send(:b2_url_encode, test_case['string'])
      assert_includes([test_case['fullyEncoded'], test_case['minimallyEncoded']], encoded)
    end
  end

end
