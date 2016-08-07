require 'test_helper'

class UserSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_session = user_sessions(:one)
  end

  test "should get index" do
    get user_sessions_url
    assert_response :success
  end

  test "should get new" do
    get new_user_session_url
    assert_response :success
  end

  test "should create user_session" do
    assert_difference('UserSession.count') do
      post user_sessions_url, params: { user_session: {  } }
    end

    assert_redirected_to user_session_url(UserSession.last)
  end

  test "should show user_session" do
    get user_session_url(@user_session)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_session_url(@user_session)
    assert_response :success
  end

  test "should update user_session" do
    patch user_session_url(@user_session), params: { user_session: {  } }
    assert_redirected_to user_session_url(@user_session)
  end

  test "should destroy user_session" do
    assert_difference('UserSession.count', -1) do
      delete user_session_url(@user_session)
    end

    assert_redirected_to user_sessions_url
  end
end
