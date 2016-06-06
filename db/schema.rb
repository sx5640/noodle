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

ActiveRecord::Schema.define(version: 20160606182336) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", force: :cascade do |t|
    t.string   "title"
    t.datetime "publication_time"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "author"
    t.string   "snippet"
    t.string   "lead_paragraph"
    t.string   "abstract"
    t.string   "source"
    t.string   "web_url"
    t.string   "media_url"
    t.string   "document_type"
    t.string   "news_desk"
    t.string   "section"
    t.string   "sub_section"
    t.string   "type_of_material"
    t.integer  "word_count"
  end

  add_index "articles", ["abstract"], name: "index_articles_on_abstract", using: :btree
  add_index "articles", ["lead_paragraph"], name: "index_articles_on_lead_paragraph", using: :btree
  add_index "articles", ["publication_time"], name: "index_articles_on_publication_time", using: :btree
  add_index "articles", ["snippet"], name: "index_articles_on_snippet", using: :btree
  add_index "articles", ["title"], name: "index_articles_on_title", using: :btree

  create_table "keyword_analyses", force: :cascade do |t|
    t.integer  "article_id"
    t.integer  "keyword_id"
    t.float    "relevance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float    "confidence"
    t.string   "name"
  end

  add_index "keyword_analyses", ["article_id"], name: "index_keyword_analyses_on_article_id", using: :btree
  add_index "keyword_analyses", ["keyword_id"], name: "index_keyword_analyses_on_keyword_id", using: :btree
  add_index "keyword_analyses", ["name"], name: "index_keyword_analyses_on_name", using: :btree

  create_table "keywords", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "keyword_type"
  end

  add_index "keywords", ["name"], name: "index_keywords_on_name", using: :btree

  create_table "saved_timeline_notes", force: :cascade do |t|
    t.text     "text"
    t.integer  "zone_num"
    t.integer  "saved_timeline_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "saved_timelines", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "search_string"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                        null: false
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree

end
