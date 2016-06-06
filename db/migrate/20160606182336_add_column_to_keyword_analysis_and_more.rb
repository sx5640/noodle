class AddColumnToKeywordAnalysisAndMore < ActiveRecord::Migration
  def change
    add_column :keyword_analyses, :name, :string
    add_index :keyword_analyses, :name
  end
end
