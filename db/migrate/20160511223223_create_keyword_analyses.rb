class CreateKeywordAnalyses < ActiveRecord::Migration
  def change
    create_table :keyword_analyses do |t|
      t.integer :article_id
      t.integer :keyword_id
      t.float :relevance

      t.timestamps null: false
    end
  end
end
