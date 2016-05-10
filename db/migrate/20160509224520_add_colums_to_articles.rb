class AddColumsToArticles < ActiveRecord::Migration
  def change
    change_table :articles do |t|
      t.string :author
      t.string :snippet
      t.string :lead_paragraph
      t.string :abstract
      t.string :source
      t.string :web_url
      t.string :media_url
      t.string :document_type
      t.string :news_desk
      t.string :section
      t.string :sub_section
      t.string :type_of_material
      t.integer :word_count
    end
    change_table :keywords do |t|
      t.remove :article_id, :relevance
    end
  end
end
