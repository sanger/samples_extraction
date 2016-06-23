json.array!(@process_types) do |process_type|
  json.extract! process_type, :id, :name
  json.url process_type_url(process_type, format: :json)
end
