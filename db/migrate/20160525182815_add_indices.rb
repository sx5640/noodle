class AddIndices < ActiveRecord::Migration
  def change
    add_index :articles, :publication_time
    add_index :articles, :title
    add_index :articles, :abstract
    add_index :articles, :lead_paragraph
    add_index :articles, :snippet

    add_index :keywords, :name

    add_index :keyword_analyses, :article_id
    add_index :keyword_analyses, :keyword_id
  end
end
