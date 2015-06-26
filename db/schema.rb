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

ActiveRecord::Schema.define(version: 20150617221117) do

  create_table "annotation_layers", force: :cascade do |t|
    t.string   "layer_id"
    t.string   "layer_type"
    t.string   "context"
    t.string   "label"
    t.string   "motivation"
    t.string   "description"
    t.string   "license"
    t.string   "otherContent"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "annotation_lists", force: :cascade do |t|
    t.string   "list_id"
    t.string   "list_type"
    t.string   "resources"
    t.string   "within"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "layer_lists_maps", force: :cascade do |t|
    t.string   "layer_id"
    t.integer  "sequence"
    t.string   "list_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
