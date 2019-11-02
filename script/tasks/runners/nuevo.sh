#!/bin/sh
echo '{
  "create_assets": ["?p"],
  "delete_assets": ["?p"],
  "add_asset": [["?g", "?p"]],
  "remove_asset": [["?g", "2a540e59-eb76-43c7-ac96-2222b1a53a41"]],
  "create_asset_groups": ["?g"],
  "delete_asset_groups": ["?g"],
  "add_facts": [
    ["?p", "a", "Plate"]
  ],
  "remove_facts": [
    ["?p", "a", "Plate"]
  ]
}'
