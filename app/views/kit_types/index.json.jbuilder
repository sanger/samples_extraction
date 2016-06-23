json.array!(@kit_types) do |kit_type|
  json.extract! kit_type, :id, :name, :target_type, :process_type_id
  json.url kit_type_url(kit_type, format: :json)
end
