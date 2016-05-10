# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

for i in (0 .. 100)
  response = Article.get_articles('Elon Musk', i, 20130101, 20170101)
  puts(i)

  if response["response"]["docs"].empty?
    break
  else
    response["response"]["docs"].each do |entry|
      data = entry.select {|k,v| Article.new.attributes.keys.include?(k)}
      article = Article.new(data)
      article[:title] = entry['headline']['main']
      if entry['byline'] && !entry['byline'].empty?
        article[:author] = entry['byline']['original']
      end
      article[:media_url] = entry['multimedia'].first['url'] unless entry['multimedia'].empty?
      article[:publication_time] = entry['pub_date'].to_datetime
      article.save

      entry['keywords'].each do |keyword|
        keyword_temp = keyword['value'].split(' (')
        keyword['value'] = keyword_temp[0]
        if keyword['name'] == 'persons'
          name_temp = keyword['value'].split(', ')
          if name_temp[1]
            keyword['value'] = name_temp[1] + ' ' + name_temp[0]
          end
        end
        finding = Keyword.find_by(name: keyword['value'], keyword_type: keyword['name'])
        if finding
          article.keywords << finding
        else
          article.keywords.create(name: keyword['value'], keyword_type: keyword['name'])
        end
      end
    end
  end

end
