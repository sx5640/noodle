class Article < ActiveRecord::Base
  has_many :keywords

  def self.get_articles(search_terms)
    response = HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{search_terms}&api-key=#{Rails.application.secrets.nytimes_key}")

    binding.pry
  end
end
