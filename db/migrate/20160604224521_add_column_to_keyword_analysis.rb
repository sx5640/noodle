class AddColumnToKeywordAnalysis < ActiveRecord::Migration
  def change
    add_column :keyword_analyses, :confidence, :float
  end
end
