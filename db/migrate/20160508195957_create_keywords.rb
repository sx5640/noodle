class CreateKeywords < ActiveRecord::Migration
  def change
    create_table :keywords do |t|
      t.string :name
      t.integer :article_id
      t.integer :relevance

      t.timestamps null: false
    end
  end
end
