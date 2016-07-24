json.extract! user, :id, :barcode, :username, :fullname, :created_at, :updated_at
json.url user_url(user, format: :json)
