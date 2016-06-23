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

ActiveRecord::Schema.define(version: 20160623160701) do

  create_table "asset_groups", force: :cascade do |t|
    t.integer  "step_id",    limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "asset_groups", ["step_id"], name: "index_asset_groups_on_step_id", using: :btree

  create_table "capacities", force: :cascade do |t|
    t.integer  "instrument_id",   limit: 4
    t.integer  "process_type_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "capacities", ["instrument_id"], name: "index_capacities_on_instrument_id", using: :btree
  add_index "capacities", ["process_type_id"], name: "index_capacities_on_process_type_id", using: :btree

  create_table "enroled_assets", force: :cascade do |t|
    t.integer  "asset_group_id", limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "enroled_assets", ["asset_group_id"], name: "index_enroled_assets_on_asset_group_id", using: :btree

  create_table "instruments", force: :cascade do |t|
    t.string   "barcode",    limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "kit_types", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "target_type",     limit: 255
    t.integer  "process_type_id", limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "kit_types", ["process_type_id"], name: "index_kit_types_on_process_type_id", using: :btree

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

  create_table "marks", force: :cascade do |t|
    t.integer  "asset_group_id", limit: 4
    t.string   "name",           limit: 255
    t.date     "complete?"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "marks", ["asset_group_id"], name: "index_marks_on_asset_group_id", using: :btree

  create_table "process_progresses", force: :cascade do |t|
    t.integer  "capacity_id", limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "process_progresses", ["capacity_id"], name: "index_process_progresses_on_capacity_id", using: :btree

  create_table "process_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "steps", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",      limit: 255
    t.string   "password",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_foreign_key "asset_groups", "steps"
  add_foreign_key "capacities", "instruments"
  add_foreign_key "capacities", "process_types"
  add_foreign_key "enroled_assets", "asset_groups"
  add_foreign_key "kit_types", "process_types"
  add_foreign_key "kits", "kit_types"
  add_foreign_key "marks", "asset_groups"
  add_foreign_key "process_progresses", "capacities"
end
