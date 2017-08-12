json.array!(@assets) do |asset|
  json.extract! asset, :id
  json.url n3_url_resource_for(asset, format: :json)
end
