class Keyword < ActiveRecord::Base
  has_many :keyword_analyses
  has_many :articles, through: :keyword_analyses

  def self.get_watson_keywords(article)
    response = JSON.parse(Typhoeus.get("http://gateway-a.watsonplatform.net/calls/url/URLGetRankedKeywords?apikey=#{Rails.application.secrets.watson_alchemyapi_key}&url=#{article[:web_url]}&outputMode=json").body)

    if response["status"] == 'OK'
      response['keywords'].each do |keyword|
        # this is to avoid brackets like Tesla (cooperation)

        # if the keyword exists, create a new_keyword_analysis that connect the existing_keyword to current article
        existing_keyword = self.find_by(name: keyword['text'])
        if existing_keyword
          new_keyword_analysis = article.keyword_analyses.new
          new_keyword_analysis.keyword = existing_keyword
          # calculate relevance based on the ranking of the keyword given by NYTimes
          if keyword['relevance'].to_f
            new_keyword_analysis[:relevance] = keyword['relevance'].to_f
          else
            new_keyword_analysis[:relevance] = 0.1
          end
        else
          # otherwise, create a new_keyword, then create a new_keyword_analysis that connect it with the current article
          new_keyword = self.create(name: keyword['text'])
          new_keyword_analysis = article.keyword_analyses.new
          new_keyword_analysis.keyword = new_keyword
          if keyword['relevance'].to_f
            new_keyword_analysis[:relevance] = keyword['relevance'].to_f
          else
            new_keyword_analysis[:relevance] = 0.1
          end
        end
        new_keyword_analysis.save
      end
    end
  end

  def self.get_nytimes_keywords(entry, article)
    entry['keywords'].each do |keyword|

      # this is to avoid brackets like Tesla (cooperation)
      keyword_temp = keyword['value'].titleize.split(' (')
      keyword['value'] = keyword_temp[0]
      # this is to reformat names from Musk, Elon to Elon Musk
      if keyword['value'] && keyword['name'] == 'persons'
        name_temp = keyword['value'].split(', ')
        if name_temp[1]
          keyword['value'] = name_temp[1] + ' ' + name_temp[0]
        end
      end
      # if the keyword exists, create a new_keyword_analysis that connect the existing_keyword to current article
      existing_keyword = self.find_by(name: keyword['value'], keyword_type: keyword['name'])
      if existing_keyword
        new_keyword_analysis = article.keyword_analyses.new
        new_keyword_analysis.keyword = existing_keyword
        # calculate relevance based on the ranking of the keyword given by NYTimes
        if keyword['rank']
          new_keyword_analysis[:relevance] = 0.5 + (0.5 / keyword['rank'].to_f)
        else
          new_keyword_analysis[:relevance] = 0.5
        end
      else
        # otherwise, create a new_keyword, then create a new_keyword_analysis that connect it with the current article
        new_keyword = self.create(name: keyword['value'], keyword_type: keyword['name'])
        new_keyword_analysis = article.keyword_analyses.new
        new_keyword_analysis.keyword = new_keyword
        if keyword['rank']
          new_keyword_analysis[:relevance] = 0.5 + (0.5 / keyword['rank'].to_f)
        else
          new_keyword_analysis[:relevance] = 0.5
        end
      end
      new_keyword_analysis.save
    end
  end

  # define a method that remove generic keywords from keyword list of each zone
  def self.remove_generic_keywords(zones)
    top_num = 9

    # get top 20 keywords from each zone, put together and sort by how many times they appear in all zones
    all_keywords = []
    zones.each do |zone|
      all_keywords += zones[0][:keywords][0..top_num].map { |e| e[:keyword]  }
    end

    flatten_all_keywrds = all_keywords.flatten

    flatten_all_keywrds.sort { |a, b| all_keywords.count(b) <=> all_keywords.count(a) }

    generic_keywords = flatten_all_keywrds[0..19]
    puts "generic_keywords: #{generic_keywords}"

    zones.each do |zone|
      zone[:keywords][0..top_num].each do |keyword|
        if generic_keywords.include?(keyword[:keyword])
          zone[:keywords].delete(keyword)
        end
      end
    end
    return zones
  end
end
