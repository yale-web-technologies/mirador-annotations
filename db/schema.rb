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

ActiveRecord::Schema.define(version: 20151008195119) do

  create_table "anno_list_layer_versions", force: :cascade do |t|
    t.string   "all_id"
    t.string   "all_type"
    t.integer  "all_version"
    t.string   "all_content"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "annotation_layers", force: :cascade do |t|
    t.string   "layer_id"
    t.string   "layer_type"
    t.string   "motivation"
    t.string   "label"
    t.string   "description"
    t.string   "license"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "version"
  end

  add_index "annotation_layers", ["layer_id"], name: "index_annotation_layers_on_layer_id"

  create_table "annotation_lists", force: :cascade do |t|
    t.string   "list_id"
    t.string   "list_type"
    t.string   "label"
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "version"
  end

  add_index "annotation_lists", ["list_id"], name: "index_annotation_lists_on_list_id"

  create_table "annotations", force: :cascade do |t|
    t.string   "annotation_id"
    t.string   "annotation_type"
    t.string   "motivation"
    t.string   "label"
    t.string   "description"
    t.string   "on"
    t.string   "canvas"
    t.string   "manifest"
    t.string   "resource"
    t.boolean  "active"
    t.integer  "version"
    t.string   "annotated_by"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "annotations", ["annotation_id"], name: "index_annotations_on_annotation_id"

  create_table "groups", force: :cascade do |t|
    t.string   "group_id"
    t.string   "group_description"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "site_id"
    t.string   "role"
    t.text     "permissions"
  end

  create_table "groups_users", id: false, force: :cascade do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  add_index "groups_users", ["group_id"], name: "index_groups_users_on_group_id"
  add_index "groups_users", ["user_id"], name: "index_groups_users_on_user_id"

  create_table "groups_webacls", id: false, force: :cascade do |t|
    t.integer "group_id"
    t.integer "webacl_id"
  end

  add_index "groups_webacls", ["group_id"], name: "index_groups_webacls_on_group_id"
  add_index "groups_webacls", ["webacl_id"], name: "index_groups_webacls_on_webacl_id"

  create_table "layer_lists_maps", force: :cascade do |t|
    t.string   "layer_id"
    t.integer  "sequence"
    t.string   "list_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "layer_lists_maps", ["layer_id"], name: "index_layer_lists_maps_on_layer_id"
  add_index "layer_lists_maps", ["list_id"], name: "index_layer_lists_maps_on_list_id"

  create_table "list_annotations_maps", force: :cascade do |t|
    t.string   "list_id"
    t.integer  "sequence"
    t.string   "annotation_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "list_annotations_maps", ["annotation_id"], name: "index_list_annotations_maps_on_annotation_id"
  add_index "list_annotations_maps", ["list_id"], name: "index_list_annotations_maps_on_list_id"

  create_table "sites", force: :cascade do |t|
    t.string   "site_id"
    t.string   "site_title"
    t.string   "site_description"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "uid"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "webacls", force: :cascade do |t|
    t.string   "resource_id"
    t.string   "acl_mode"
    t.string   "group_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

end
