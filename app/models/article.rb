class Article < ActiveRecord::Base
  has_and_belongs_to_many :keywords

  def self.get_articles(search_terms, page_num, begin_date, end_date)
    response = HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{search_terms}&page=#{page_num}&begin_date=#{begin_date}&end_date=#{end_date}&api-key=#{Rails.application.secrets.nytimes_key}")
  end
end
