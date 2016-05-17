class RenameColumnFromSavedTimeline < ActiveRecord::Migration
  def change
    rename_column :saved_timelines, :keyword, :search_string
  end
end
