class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title
      t.datetime :publication_time

      t.timestamps null: false
    end
  end
end
