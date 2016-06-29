# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160628113258) do

  create_table "activities", force: :cascade do |t|
    t.integer  "activity_type_id", limit: 4
    t.date     "completion_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["activity_type_id"], name: "index_activities_on_activity_type_id", using: :btree

  create_table "activity_type_step_types", force: :cascade do |t|
    t.integer  "activity_type_id", limit: 4
    t.integer  "step_type_id",     limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "activity_type_step_types", ["activity_type_id"], name: "index_activity_type_step_types_on_activity_type_id", using: :btree
  add_index "activity_type_step_types", ["step_type_id"], name: "index_activity_type_step_types_on_step_type_id", using: :btree

  create_table "activity_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "asset_facts", force: :cascade do |t|
    t.integer  "asset_id",   limit: 4
    t.integer  "fact_id",    limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "asset_facts", ["asset_id"], name: "index_asset_facts_on_asset_id", using: :btree
  add_index "asset_facts", ["fact_id"], name: "index_asset_facts_on_fact_id", using: :btree

  create_table "assets", force: :cascade do |t|
    t.string   "barcode",    limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "capacities", force: :cascade do |t|
    t.integer  "instrument_id",    limit: 4
    t.integer  "activity_type_id", limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "capacities", ["activity_type_id"], name: "index_capacities_on_activity_type_id", using: :btree
  add_index "capacities", ["instrument_id"], name: "index_capacities_on_instrument_id", using: :btree

  create_table "condition_groups", force: :cascade do |t|
    t.integer "step_type_id", limit: 4
    t.integer "cardinality",  limit: 4
  end

  add_index "condition_groups", ["step_type_id"], name: "index_condition_groups_on_step_type_id", using: :btree

  create_table "conditions", force: :cascade do |t|
    t.integer  "condition_group_id",   limit: 4
    t.string   "predicate",            limit: 255, null: false
    t.string   "object",               limit: 255
    t.integer  "subject_condition_id", limit: 4
    t.integer  "object_condition_id",  limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "conditions", ["condition_group_id"], name: "index_conditions_on_condition_group_id", using: :btree

  create_table "facts", force: :cascade do |t|
    t.string   "predicate",  limit: 255, null: false
    t.string   "object",     limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "instruments", force: :cascade do |t|
    t.string   "barcode",    limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "kit_types", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.string   "target_type",      limit: 255
    t.integer  "activity_type_id", limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "kit_types", ["activity_type_id"], name: "index_kit_types_on_activity_type_id", using: :btree

  create_table "kits", force: :cascade do |t|
    t.string   "barcode",                 limit: 255
    t.integer  "max_num_reactions",       limit: 4
    t.integer  "num_reactions_performed", limit: 4
    t.integer  "kit_type_id",             limit: 4
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "kits", ["kit_type_id"], name: "index_kits_on_kit_type_id", using: :btree

  create_table "lab_aliquot_containers", force: :cascade do |t|
    t.string   "type",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "lab_aliquots", force: :cascade do |t|
    t.string   "type",          limit: 255
    t.float    "volume",        limit: 24
    t.float    "concentration", limit: 24
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "lab_plates", force: :cascade do |t|
    t.string   "type",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "lab_samples", force: :cascade do |t|
    t.string   "type",             limit: 255
    t.string   "sanger_sample_id", limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "step_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "steps", force: :cascade do |t|
    t.integer  "step_type_id",    limit: 4
    t.date     "completion_date"
    t.integer  "activity_id",     limit: 4
    t.integer  "asset_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "steps", ["activity_id"], name: "index_steps_on_activity_id", using: :btree
  add_index "steps", ["asset_id"], name: "index_steps_on_asset_id", using: :btree
  add_index "steps", ["step_type_id"], name: "index_steps_on_step_type_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "login",      limit: 255
    t.string   "password",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_foreign_key "activities", "activity_types"
  add_foreign_key "activity_type_step_types", "activity_types"
  add_foreign_key "activity_type_step_types", "step_types"
  add_foreign_key "asset_facts", "assets"
  add_foreign_key "asset_facts", "facts"
  add_foreign_key "capacities", "activity_types"
  add_foreign_key "capacities", "instruments"
  add_foreign_key "condition_groups", "step_types"
  add_foreign_key "conditions", "condition_groups"
  add_foreign_key "kit_types", "activity_types"
  add_foreign_key "kits", "kit_types"
  add_foreign_key "steps", "activities"
  add_foreign_key "steps", "assets"
  add_foreign_key "steps", "step_types"
end
