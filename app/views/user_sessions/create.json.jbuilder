json.extract! @user, :username, :fullname, :barcode, :role
json.url user_url(@user, format: :json)
