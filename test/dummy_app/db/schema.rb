# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_01_061824) do

  create_table "snapshot_items", force: :cascade do |t|
    t.integer "snapshot_id", null: false
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.text "object", limit: 1073741823
    t.datetime "created_at", null: false
    t.index ["item_type", "item_id"], name: "index_snapshot_items_on_item_type_and_item_id"
    t.index ["snapshot_id"], name: "index_snapshot_items_on_snapshot_id"
  end

  create_table "snapshots", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "identifier", null: false
    t.string "user_type"
    t.integer "user_id"
    t.text "metadata", limit: 1073741823
    t.datetime "created_at", null: false
    t.index ["identifier"], name: "index_snapshots_on_identifier"
    t.index ["item_type", "item_id"], name: "index_snapshots_on_item_type_and_item_id"
    t.index ["user_type", "user_id"], name: "index_snapshots_on_user_type_and_user_id"
  end

end
