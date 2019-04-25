#!/bin/sh
echo '{
  "create_asset": ["?p"],
  "destroy_asset": ["?p"],
  "select_asset": [["?g", "?p"]],
  "unselect_asset": [["?g", "2a540e59-eb76-43c7-ac96-2222b1a53a41"]],
  "create_group": ["?g"],
  "destroy_group": ["?g"],

  "add_facts": [
    ["?p", "a", "Plate"]
  ],
  "remove_facts": [
    ["?p", "a", "Plate"]
  ]
}'
