class CreateSavedTimelineNotes < ActiveRecord::Migration
  def change
    create_table :saved_timeline_notes do |t|
      t.text :text
      t.integer :zone_num
      t.integer :saved_timeline_id

      t.timestamps null: false
    end
  end
end
