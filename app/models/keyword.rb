require "benchmark"

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
          new_keyword_analysis = article.keyword_analyses.new(name: keyword['text'])
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
          new_keyword_analysis = article.keyword_analyses.new(name: keyword['text'])
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

  def self.get_text_razor_keywords(article)
    response = JSON.parse(Typhoeus.post(
      "http://api.textrazor.com",
      headers: {
        'x-textrazor-key' => Rails.application.secrets.text_razor_key
      },
      body: {
        url: article[:web_url],
        extractors: 'entities'
      }
    ).body)

    puts "article_id = #{article[:id]}"

    if response['error']
      puts("error: #{response['error']}")
      article.destroy

    elsif response['response']['entities']
      data = response['response']['entities']
      data.sort! { |a, b| b['relevanceScore'] <=> a['relevanceScore']}
      data.uniq! { |e| e['entityId']}
      data.select! {|e| e['confidenceScore'] > 1}

      data.each do |keyword|
        # if the keyword exists, create a new_keyword_analysis that connect the existing_keyword to current article
        existing_keyword = self.find_by(name: keyword['entityId'])
        if existing_keyword
          new_keyword_analysis = article.keyword_analyses.new(name: keyword['entityId'])
          new_keyword_analysis.keyword = existing_keyword

          if keyword['confidenceScore']
            new_keyword_analysis[:confidence] = keyword['confidenceScore'].to_f
          end

          if keyword['relevanceScore']
            new_keyword_analysis[:relevance] = keyword['relevanceScore'].to_f
          else
            new_keyword_analysis[:relevance] = 0.1
          end
        else
          # otherwise, create a new_keyword, then create a new_keyword_analysis that connect it with the current article
          new_keyword = self.create(name: keyword['entityId'])
          new_keyword_analysis = article.keyword_analyses.new(name: keyword['entityId'])
          new_keyword_analysis.keyword = new_keyword

          if keyword['confidenceScore']
            new_keyword_analysis[:confidence] = keyword['confidenceScore'].to_f
          end

          if keyword['relevanceScore'].to_f
            new_keyword_analysis[:relevance] = keyword['relevanceScore'].to_f
          else
            new_keyword_analysis[:relevance] = 0.1
          end
        end
        new_keyword_analysis.save
      end
    end
  end
  # define a method that remove generic keywords from keyword list of each zone
  def self.remove_generic_keywords(zones)
    puts "#{Time.now.strftime("%m/%d/%Y %T,%L")}************* Removing Generic Keywords *************"
    top_num = 9
    if zones.length <= 1
      allowed_generic_level = zones.length
    else
      allowed_generic_level = zones.length / 2
    end

    # get top 20 keywords from each zone, put together and select by how many times they appear in all zones
    all_keywords = []
    zones.each do |zone|
      all_keywords += zone[:keywords][0..top_num].map { |e| e[:keyword]  }
    end

    uniq_all_keywords = all_keywords.uniq.sort

    puts "============= Top #{top_num+1} Keywords ==============="
    puts "all_keywords size: #{all_keywords.size}"
    uniq_all_keywords.each { |e|  puts "#{e}: #{all_keywords.count(e)}"}
    puts "============================"

    generic_keywords = uniq_all_keywords.select { |e| all_keywords.count(e) > allowed_generic_level }

    puts "============= Generic Keywords ==============="
    generic_keywords.each { |e|  puts "#{e}: #{all_keywords.count(e)}"}
    puts "============================"

    # for each timezone, remove generic_keywords from their list
    zones.each do |zone|
      zone[:keywords][0..top_num].each do |keyword|
        if generic_keywords.include?(keyword[:keyword])
          zone[:keywords].delete(keyword)
        end
      end
    end
    return zones
  end

  def self.generate_keywords(articles)
    # creating an empty keyword collection for the given article. the key will be the keyword, and the value will be the sum of relevance of the keyword among all selected articles
    puts "#{Time.now.strftime("%m/%d/%Y %T,%L")}************* Generating Keywords, totla: #{articles.size} *************"
    article_ids = articles.map { |e| e[:id]  }

    keywords_collection = {}

    t = Benchmark.measure do

      KeywordAnalysis.joins(:article).where("article_id in (?)", article_ids).each do |keyword_analysis|
        # iterate through all article and keyword pairs and try to find the keyword_analysis that connect them.
        keyword = keyword_analysis[:name]
        if keywords_collection.keys.include?(keyword)
          keywords_collection["#{keyword}"] += keyword_analysis.relevance
        else
          keywords_collection["#{keyword}"] = keyword_analysis.relevance
        end
      end
    end
    puts "************* Generating Keywords, iteration, totla: #{t} *************"
    # rank the keyword and output in arry
    ranking_keyword = keywords_collection.sort_by {|keyword, relevance| relevance}
    result = []
    ranking_keyword.reverse!.each do |keyword_relevance|
      result << {keyword: keyword_relevance[0].to_s, relevance: keyword_relevance[1]}
    end
    puts "#{Time.now.strftime("%m/%d/%Y %T,%L")}************* Generating Keywords, end, totla: #{articles.size} *************"
    return result
  end

end
