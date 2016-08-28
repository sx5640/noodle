# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


# How To Seed Your Own data

# Article.get_all_nytimes_articles("you keyword", start date in number, end date in number, step of each earch: "year", "month", or integer which will represent days)
Article.get_guardian_articles('Elon Musk', '2013-06-01')

a = Article.where("source = ?", 'Guardian').select {|e| e.keywords.size == 0 }

a.each { |e| e.destroy  }


Article.get_all_nytimes_articles('Elon Musk', 20130601, 20170130, "year")

b = KeywordAnalysis.joins(:article).where('articles.source = ?', 'New York Times')

b.each do |k|
  k.update_attributes(relevance: 0)
end
# Article.get_all_nytimes_articles('Donald Trump', 20100101, 20160530, 15)
