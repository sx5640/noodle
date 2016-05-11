class Keyword < ActiveRecord::Base
  has_many :keyword_analyses
  has_many :articles, through: :keyword_analyses
end
