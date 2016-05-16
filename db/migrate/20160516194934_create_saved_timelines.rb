class CreateSavedTimelines < ActiveRecord::Migration
  def change
    create_table :saved_timelines do |t|
      t.integer :user_id
      t.string :keyword
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps null: false
    end
  end
end
