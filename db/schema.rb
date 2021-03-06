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

ActiveRecord::Schema.define(version: 20171107193813) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "version"
    t.integer  "order_weight", default: 0
  end

  add_index "annotation_layers", ["layer_id"], name: "index_annotation_layers_on_layer_id", using: :btree

  create_table "annotation_layers_groups", id: false, force: :cascade do |t|
    t.integer "group_id"
    t.integer "annotation_layer_id"
  end

  add_index "annotation_layers_groups", ["annotation_layer_id"], name: "index_annotation_layers_groups_on_annotation_layer_id", using: :btree
  add_index "annotation_layers_groups", ["group_id"], name: "index_annotation_layers_groups_on_group_id", using: :btree

  create_table "annotation_lists", force: :cascade do |t|
    t.string   "list_id"
    t.string   "list_type"
    t.string   "label"
    t.string   "description"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "version"
    t.integer  "annotation_layer_id"
    t.integer  "canvas_id"
  end

  add_index "annotation_lists", ["annotation_layer_id"], name: "index_annotation_lists_on_annotation_layer_id", using: :btree
  add_index "annotation_lists", ["canvas_id"], name: "index_annotation_lists_on_canvas_id", using: :btree
  add_index "annotation_lists", ["list_id"], name: "index_annotation_lists_on_list_id", using: :btree

  create_table "annotation_tag_maps", force: :cascade do |t|
    t.integer  "annotation_id"
    t.integer  "annotation_tag_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "annotation_tags", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

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
    t.string   "service_block"
    t.integer  "order_weight"
  end

  add_index "annotations", ["annotation_id"], name: "index_annotations_on_annotation_id", using: :btree

  create_table "canvas_mapping_old_news", force: :cascade do |t|
    t.string   "old_canvas_id"
    t.string   "new_canvas_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "canvases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "collections", force: :cascade do |t|
    t.string   "collection_id"
    t.string   "label"
    t.text     "description"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

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

  add_index "groups_users", ["group_id"], name: "index_groups_users_on_group_id", using: :btree
  add_index "groups_users", ["user_id"], name: "index_groups_users_on_user_id", using: :btree

  create_table "groups_webacls", id: false, force: :cascade do |t|
    t.integer "group_id"
    t.integer "webacls_id"
  end

  add_index "groups_webacls", ["group_id"], name: "index_groups_webacls_on_group_id", using: :btree
  add_index "groups_webacls", ["webacls_id"], name: "index_groups_webacls_on_webacls_id", using: :btree

  create_table "layer_lists_maps", force: :cascade do |t|
    t.string   "layer_id"
    t.integer  "sequence"
    t.string   "list_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "layer_lists_maps", ["layer_id"], name: "index_layer_lists_maps_on_layer_id", using: :btree
  add_index "layer_lists_maps", ["list_id"], name: "index_layer_lists_maps_on_list_id", using: :btree

  create_table "layer_mappings", force: :cascade do |t|
    t.string   "layer_id"
    t.string   "new_layer_id"
    t.string   "label"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "list_annotations_maps", force: :cascade do |t|
    t.string   "list_id"
    t.integer  "sequence"
    t.string   "annotation_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "list_annotations_maps", ["annotation_id"], name: "index_list_annotations_maps_on_annotation_id", using: :btree
  add_index "list_annotations_maps", ["list_id"], name: "index_list_annotations_maps_on_list_id", using: :btree

  create_table "sites", force: :cascade do |t|
    t.string   "site_id"
    t.string   "site_title"
    t.string   "site_description"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",               default: "", null: false
    t.string   "encrypted_password",  default: "", null: false
    t.string   "tgToken"
    t.string   "bearerToken"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",       default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "uid"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["tgToken"], name: "index_users_on_tgToken", unique: true, using: :btree

  create_table "users_webacls", force: :cascade do |t|
    t.integer "user_id"
    t.integer "group_id"
    t.integer "webacls_id"
  end

  add_index "users_webacls", ["group_id"], name: "index_users_webacls_on_group_id", using: :btree
  add_index "users_webacls", ["user_id"], name: "index_users_webacls_on_user_id", using: :btree
  add_index "users_webacls", ["webacls_id"], name: "index_users_webacls_on_webacls_id", using: :btree

  create_table "webacls", force: :cascade do |t|
    t.string   "resource_id"
    t.string   "acl_mode"
    t.string   "group_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_foreign_key "annotation_lists", "annotation_layers"
  add_foreign_key "annotation_lists", "canvases"
end
