class Article < ActiveRecord::Base
  has_many :keyword_analyses
  has_many :keywords, through: :keyword_analyses

  def self.get_nytimes_articles(search_terms, begin_date, end_date)

    for i in (0 .. 100)
      response = HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{search_terms}&page=#{i}&begin_date=#{begin_date}&end_date=#{end_date}&api-key=#{Rails.application.secrets.nytimes_key}")
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
            existing_keyword = Keyword.find_by(name: keyword['value'], keyword_type: keyword['name'])
            if existing_keyword
              new_keyword_analysis = article.keyword_analyses.new
              new_keyword_analysis.keyword = existing_keyword
              new_keyword_analysis[:relevance] = 0.5 + (0.5 / keyword['rank'].to_f)
              new_keyword_analysis.save
            else
              new_keyword = Keyword.create(name: keyword['value'], keyword_type: keyword['name'])
              new_keyword_analysis = article.keyword_analyses.new
              new_keyword_analysis.keyword = new_keyword
              new_keyword_analysis[:relevance] = 0.5 + (0.5 / keyword['rank'].to_f)
              new_keyword_analysis.save
            end
          end
        end
      end

    end
  end
end
