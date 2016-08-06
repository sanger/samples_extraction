json.extract! @user, :username, :fullname, :barcode
json.url user_url(@user, format: :json)
