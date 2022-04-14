obj = {
  create_assets: ["?p"],
  create_asset_groups: ["?Eduardo Martin"],
  add_assets: [
    ["?Eduardo Martin", ["?p"]],
    ["?p"]
  ],
  add_facts: [["?p", "a", "Tube"]],
  delete_asset_groups: ["a8e395a9-a2fb-4af6-8678-85e34ec2b448"]
}.to_json

puts obj
