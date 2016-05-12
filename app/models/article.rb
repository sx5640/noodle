class Article < ActiveRecord::Base
  has_many :keyword_analyses
  has_many :keywords, through: :keyword_analyses
  # defining a method dedicated to get articles from NYTimes
  def self.get_nytimes_articles(search_terms, begin_date, end_date)
    # loop through page 0 to page 100
    for i in (0 .. 100)
      # get 10 articles with given keyword, timeframe and page #
      response = HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{search_terms}&page=#{i}&begin_date=#{begin_date}&end_date=#{end_date}&api-key=#{Rails.application.secrets.nytimes_key}")
      puts(i)
      # if no article returns, break the loop
      if response["response"]["docs"].empty?
        break
      else
        # iterate through the 10 articles get from each call, and clean up the data
        response["response"]["docs"].each do |entry|
          # select data from each article where the JSON attributes has the same name with out Article class object.
          # everything from the JSON taht is not selected cannot be saved directly into database and needed clean up
          data = entry.select {|k,v| Article.new.attributes.keys.include?(k)}
          article = Article.new(data)
          # clean up the title
          article[:title] = entry['headline']['main']
          # clean up author
          if entry['byline'] && !entry['byline'].empty?
            article[:author] = entry['byline']['original']
          end
          # get the first multimedia from the list of media
          article[:media_url] = entry['multimedia'].first['url'] unless entry['multimedia'].empty?
          # set publication datetime
          article[:publication_time] = entry['pub_date'].to_datetime
          # save int database
          article.save

          # now keywords
          entry['keywords'].each do |keyword|
            # this is to avoid brackets like Tesla (cooperation)
            keyword_temp = keyword['value'].split(' (')
            keyword['value'] = keyword_temp[0]
            # this is to reformat names from Musk, Elon to Elon Musk
            if keyword['name'] == 'persons'
              name_temp = keyword['value'].split(', ')
              if name_temp[1]
                keyword['value'] = name_temp[1] + ' ' + name_temp[0]
              end
            end
            # if the keyword exists, create a new_keyword_analysis that connect the existing_keyword to current article
            existing_keyword = Keyword.find_by(name: keyword['value'], keyword_type: keyword['name'])
            if existing_keyword
              new_keyword_analysis = article.keyword_analyses.new
              new_keyword_analysis.keyword = existing_keyword
              # calculate relevance based on the ranking of the keyword given by NYTimes
              new_keyword_analysis[:relevance] = 0.5 + (0.5 / keyword['rank'].to_f)
              # save
              new_keyword_analysis.save
            else
              # otherwise, create a new_keyword, then create a new_keyword_analysis that connect it with the current article
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
