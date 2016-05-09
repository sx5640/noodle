# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

article1 = Article.create(title: 'abc', publication_time: Time.now)
article1 = Article.create(title: 'def', publication_time: Time.now)

keyword1 = Keyword.create(name: "first", article_id: 1, relevance: 1)
keyword2 = Keyword.create(name: "second", article_id: 1, relevance: 2)
keyword3 = Keyword.create(name: "first", article_id: 2, relevance: 1)
keyword4 = Keyword.create(name: "third", article_id: 2, relevance: 2)
