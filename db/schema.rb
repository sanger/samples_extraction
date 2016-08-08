# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160808152447) do

  create_table "actions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "action_type",                null: false
    t.integer  "step_type_id"
    t.integer  "subject_condition_group_id"
    t.string   "predicate",                  null: false
    t.string   "object"
    t.integer  "object_condition_group_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["object_condition_group_id"], name: "index_actions_on_object_condition_group_id", using: :btree
    t.index ["step_type_id"], name: "index_actions_on_step_type_id", using: :btree
    t.index ["subject_condition_group_id"], name: "index_actions_on_subject_condition_group_id", using: :btree
  end

  create_table "activities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "activity_type_id"
    t.integer  "instrument_id"
    t.integer  "asset_group_id"
    t.integer  "kit_id"
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["activity_type_id"], name: "index_activities_on_activity_type_id", using: :btree
    t.index ["asset_group_id"], name: "index_activities_on_asset_group_id", using: :btree
    t.index ["instrument_id"], name: "index_activities_on_instrument_id", using: :btree
    t.index ["kit_id"], name: "index_activities_on_kit_id", using: :btree
  end

  create_table "activity_type_step_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "activity_type_id"
    t.integer  "step_type_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["activity_type_id"], name: "index_activity_type_step_types_on_activity_type_id", using: :btree
    t.index ["step_type_id"], name: "index_activity_type_step_types_on_step_type_id", using: :btree
  end

  create_table "activity_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "superceded_by_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["superceded_by_id"], name: "index_activity_types_on_superceded_by_id", using: :btree
  end

  create_table "activity_types_instruments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "instrument_id"
    t.integer  "activity_type_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["activity_type_id"], name: "index_activity_types_instruments_on_activity_type_id", using: :btree
    t.index ["instrument_id"], name: "index_activity_types_instruments_on_instrument_id", using: :btree
  end

  create_table "asset_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "asset_groups_assets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "asset_id"
    t.integer  "asset_group_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["asset_group_id"], name: "index_asset_groups_assets_on_asset_group_id", using: :btree
    t.index ["asset_id"], name: "index_asset_groups_assets_on_asset_id", using: :btree
  end

  create_table "asset_groups_steps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "asset_group_id"
    t.integer  "step_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["asset_group_id"], name: "index_asset_groups_steps_on_asset_group_id", using: :btree
    t.index ["step_id"], name: "index_asset_groups_steps_on_step_id", using: :btree
  end

  create_table "asset_relations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "subject_asset_id"
    t.integer  "predicate_id"
    t.integer  "object_asset_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["object_asset_id"], name: "index_asset_relations_on_object_asset_id", using: :btree
    t.index ["predicate_id"], name: "index_asset_relations_on_predicate_id", using: :btree
    t.index ["subject_asset_id"], name: "index_asset_relations_on_subject_asset_id", using: :btree
  end

  create_table "assets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "uuid"
    t.string   "barcode"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "facts_count"
  end

  create_table "assets_facts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "asset_id"
    t.integer  "fact_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_assets_facts_on_asset_id", using: :btree
    t.index ["fact_id"], name: "index_assets_facts_on_fact_id", using: :btree
  end

  create_table "condition_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "name"
    t.boolean "keep_selected", default: true
    t.integer "step_type_id"
    t.integer "cardinality"
    t.index ["step_type_id"], name: "index_condition_groups_on_step_type_id", using: :btree
  end

  create_table "conditions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "condition_group_id"
    t.string   "predicate",          null: false
    t.string   "object"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["condition_group_id"], name: "index_conditions_on_condition_group_id", using: :btree
  end

  create_table "facts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "asset_id"
    t.string   "predicate",                      null: false
    t.string   "object"
    t.boolean  "literal",         default: true, null: false
    t.integer  "object_asset_id"
    t.integer  "to_add_by"
    t.integer  "to_remove_by"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["asset_id"], name: "index_facts_on_asset_id", using: :btree
    t.index ["object_asset_id"], name: "index_facts_on_object_asset_id", using: :btree
  end

  create_table "instruments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "barcode"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "kit_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "target_type"
    t.integer  "activity_type_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["activity_type_id"], name: "index_kit_types_on_activity_type_id", using: :btree
  end

  create_table "kits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "barcode",                 null: false
    t.integer  "max_num_reactions"
    t.integer  "num_reactions_performed"
    t.integer  "kit_type_id",             null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["kit_type_id"], name: "index_kits_on_kit_type_id", using: :btree
  end

  create_table "lab_aliquot_containers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lab_aliquots", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "type"
    t.float    "volume",        limit: 24
    t.float    "concentration", limit: 24
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "lab_plates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lab_samples", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "type"
    t.string   "sanger_sample_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "operations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "action_id"
    t.integer  "step_id"
    t.integer  "asset_id"
    t.string   "predicate"
    t.string   "object"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_id"], name: "index_operations_on_action_id", using: :btree
    t.index ["asset_id"], name: "index_operations_on_asset_id", using: :btree
    t.index ["step_id"], name: "index_operations_on_step_id", using: :btree
  end

  create_table "predicates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "step_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "step_template"
    t.binary   "n3_definition",    limit: 65535
    t.integer  "superceded_by_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["superceded_by_id"], name: "index_step_types_on_superceded_by_id", using: :btree
  end

  create_table "steps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "step_type_id"
    t.integer  "user_id"
    t.date     "completion_date"
    t.integer  "activity_id"
    t.integer  "asset_group_id"
    t.boolean  "in_progress?",    default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["activity_id"], name: "index_steps_on_activity_id", using: :btree
    t.index ["asset_group_id"], name: "index_steps_on_asset_group_id", using: :btree
    t.index ["step_type_id"], name: "index_steps_on_step_type_id", using: :btree
    t.index ["user_id"], name: "index_steps_on_user_id", using: :btree
  end

  create_table "uploads", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "step_id"
    t.integer  "activity_id"
    t.binary   "data",         limit: 16777215
    t.string   "filename"
    t.string   "content_type"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["activity_id"], name: "index_uploads_on_activity_id", using: :btree
    t.index ["step_id"], name: "index_uploads_on_step_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "login"
    t.string   "password"
    t.string   "barcode"
    t.string   "username"
    t.string   "fullname"
    t.string   "token"
    t.string   "role",       default: "operator"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_foreign_key "actions", "step_types"
  add_foreign_key "activities", "activity_types"
  add_foreign_key "activities", "asset_groups"
  add_foreign_key "activities", "instruments"
  add_foreign_key "activities", "kits"
  add_foreign_key "activity_type_step_types", "activity_types"
  add_foreign_key "activity_type_step_types", "step_types"
  add_foreign_key "activity_types_instruments", "activity_types"
  add_foreign_key "activity_types_instruments", "instruments"
  add_foreign_key "asset_groups_assets", "asset_groups"
  add_foreign_key "asset_groups_assets", "assets"
  add_foreign_key "asset_groups_steps", "asset_groups"
  add_foreign_key "asset_groups_steps", "steps"
  add_foreign_key "asset_relations", "predicates"
  add_foreign_key "assets_facts", "assets"
  add_foreign_key "assets_facts", "facts"
  add_foreign_key "condition_groups", "step_types"
  add_foreign_key "conditions", "condition_groups"
  add_foreign_key "facts", "assets"
  add_foreign_key "kit_types", "activity_types"
  add_foreign_key "kits", "kit_types"
  add_foreign_key "operations", "actions"
  add_foreign_key "operations", "assets"
  add_foreign_key "operations", "steps"
  add_foreign_key "steps", "activities"
  add_foreign_key "steps", "asset_groups"
  add_foreign_key "steps", "step_types"
  add_foreign_key "steps", "users"
  add_foreign_key "uploads", "activities"
  add_foreign_key "uploads", "steps"
end
