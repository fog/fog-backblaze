require_relative "test_helper"

describe "auth_response" do

  it "should require credentials" do
    connection = Fog::Storage.new(
      provider: 'backblaze',
      logger: CONNECTION.logger
    )

    error = assert_raises do
      connection.auth_response
    end

    assert_equal(error.class, Fog::Errors::Error)
    assert_includes(error.message, "B2 credentials are required, please use b2_account_id and b2_account_token or b2_key_id and b2_key_token")
  end

  it "should raise error with invalid credentials" do
    connection = Fog::Storage.new(
      provider: 'backblaze',
      b2_account_id: '123',
      b2_account_token: '123',
      logger: CONNECTION.logger
    )

    error = assert_raises do
      connection.auth_response
    end

    assert_equal(error.class, Fog::Errors::Error)
    assert_includes(error.message, "Authentication error:  (status = 401)\n" \
                                   '{"code"=>"bad_auth_token", "message"=>"", "status"=>401}')
  end

  # TODO: solve sometimes failing
  it "should give auth credentials" do
    CONNECTION.reset_token_cache
    assert_nil(CONNECTION.token_cache.auth_response)

    response = CONNECTION.auth_response

    assert(response['authorizationToken'] =~ /.+/)
    assert(response['apiUrl'] =~ /.+/)
    assert(response['downloadUrl'] =~ /.+/)

    # make sure it's saved in cache
    assert_equal(CONNECTION.token_cache.auth_response, response)
    assert_equal(CONNECTION.auth_response, response)
  end
end
