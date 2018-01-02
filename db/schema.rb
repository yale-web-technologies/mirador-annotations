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

ActiveRecord::Schema.define(version: 20171216203202) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "anno_list_layer_versions", id: :serial, force: :cascade do |t|
    t.string "all_id"
    t.string "all_type"
    t.integer "all_version"
    t.string "all_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "annotation_layers", id: :serial, force: :cascade do |t|
    t.string "layer_id"
    t.string "layer_type"
    t.string "motivation"
    t.string "label"
    t.string "description"
    t.string "license"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "version"
    t.integer "order_weight", default: 0
    t.index ["layer_id"], name: "index_annotation_layers_on_layer_id"
  end

  create_table "annotation_layers_groups", id: false, force: :cascade do |t|
    t.integer "group_id"
    t.integer "annotation_layer_id"
    t.index ["annotation_layer_id"], name: "index_annotation_layers_groups_on_annotation_layer_id"
    t.index ["group_id"], name: "index_annotation_layers_groups_on_group_id"
  end

  create_table "annotation_lists", id: :serial, force: :cascade do |t|
    t.string "list_id"
    t.string "list_type"
    t.string "label"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "version"
    t.integer "annotation_layer_id"
    t.integer "canvas_id"
    t.index ["annotation_layer_id"], name: "index_annotation_lists_on_annotation_layer_id"
    t.index ["canvas_id"], name: "index_annotation_lists_on_canvas_id"
    t.index ["list_id"], name: "index_annotation_lists_on_list_id"
  end

  create_table "annotation_tag_maps", id: :serial, force: :cascade do |t|
    t.integer "annotation_id"
    t.integer "annotation_tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "annotation_tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "annotations", id: :serial, force: :cascade do |t|
    t.string "annotation_id"
    t.string "annotation_type"
    t.string "motivation"
    t.string "label"
    t.string "description"
    t.string "on"
    t.string "canvas"
    t.string "manifest"
    t.string "resource"
    t.boolean "active"
    t.integer "version"
    t.string "annotated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "service_block"
    t.integer "order_weight"
    t.index ["annotation_id"], name: "index_annotations_on_annotation_id"
  end

  create_table "canvas_mapping_old_news", id: :serial, force: :cascade do |t|
    t.string "old_canvas_id"
    t.string "new_canvas_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "canvases", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "iiif_canvas_id"
    t.string "label"
    t.index ["iiif_canvas_id"], name: "index_canvases_on_iiif_canvas_id"
  end

  create_table "collections", id: :serial, force: :cascade do |t|
    t.string "collection_id"
    t.string "label"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "group_id"
    t.string "group_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "site_id"
    t.string "role"
    t.text "permissions"
  end

  create_table "groups_users", id: false, force: :cascade do |t|
    t.integer "group_id"
    t.integer "user_id"
    t.index ["group_id"], name: "index_groups_users_on_group_id"
    t.index ["user_id"], name: "index_groups_users_on_user_id"
  end

  create_table "groups_webacls", id: false, force: :cascade do |t|
    t.integer "group_id"
    t.integer "webacls_id"
    t.index ["group_id"], name: "index_groups_webacls_on_group_id"
    t.index ["webacls_id"], name: "index_groups_webacls_on_webacls_id"
  end

  create_table "layer_lists_maps", id: :serial, force: :cascade do |t|
    t.string "layer_id"
    t.integer "sequence"
    t.string "list_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["layer_id"], name: "index_layer_lists_maps_on_layer_id"
    t.index ["list_id"], name: "index_layer_lists_maps_on_list_id"
  end

  create_table "layer_mappings", id: :serial, force: :cascade do |t|
    t.string "layer_id"
    t.string "new_layer_id"
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "list_annotations_maps", id: :serial, force: :cascade do |t|
    t.string "list_id"
    t.integer "sequence"
    t.string "annotation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["annotation_id"], name: "index_list_annotations_maps_on_annotation_id"
    t.index ["list_id"], name: "index_list_annotations_maps_on_list_id"
  end

  create_table "sites", id: :serial, force: :cascade do |t|
    t.string "site_id"
    t.string "site_title"
    t.string "site_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "tgToken"
    t.string "bearerToken"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["tgToken"], name: "index_users_on_tgToken", unique: true
  end

  create_table "users_webacls", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "group_id"
    t.integer "webacls_id"
    t.index ["group_id"], name: "index_users_webacls_on_group_id"
    t.index ["user_id"], name: "index_users_webacls_on_user_id"
    t.index ["webacls_id"], name: "index_users_webacls_on_webacls_id"
  end

  create_table "webacls", id: :serial, force: :cascade do |t|
    t.string "resource_id"
    t.string "acl_mode"
    t.string "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "annotation_lists", "annotation_layers"
  add_foreign_key "annotation_lists", "canvases"
end
