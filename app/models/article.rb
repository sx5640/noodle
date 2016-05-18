class Article < ActiveRecord::Base
  has_many :keyword_analyses
  has_many :keywords, through: :keyword_analyses
  has_many :saved_timelines
  # defining a method dedicated to get articles from NYTimes
  def self.get_nytimes_articles(search_terms, begin_date, end_date)
    articles = []
    # loop through page 0 to page 100
    for i in (0 .. 100)
      # get 10 articles with given keyword, timeframe and page #
      response = HTTParty.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{search_terms}&page=#{i}&begin_date=#{begin_date}&end_date=#{end_date}&sort=newest&api-key=#{Rails.application.secrets.nytimes_key}")
      puts(i)
      # if no article returns, break the loop
      if response["response"]["docs"].empty?
        break
      else
        # iterate through the 10 articles get from each call, and clean up the data
        articles << response["response"]["docs"]
        response["response"]["docs"].each do |entry|
          # select data from each article where the JSON attributes has the same name with out Article class object.
          # everything from the JSON taht is not selected cannot be saved directly into database and needed clean up
          data = entry.select {|k,v| self.new.attributes.keys.include?(k)}
          article = self.new(data)
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
            if keyword['value'] && keyword['name'] == 'persons'
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
    return articles
  end
  # defining a method that select articles based on the data given from the params
  def self.get_all_nytimes_articles(search_terms, begin_date, end_date, step)
    case step
    when "year"
      step = 1.year
    when "month"
      step = 1.month
    else
      step = step.day
    end
    end_time_cycle = Date.strptime(end_date.to_s,'%Y%m%d')
    start_time_cycle = end_time_cycle - step
    while start_time_cycle.strftime('%Y%m%d').to_i > begin_date
      puts "#{start_time_cycle} To #{end_time_cycle}"
      articles = Article.get_nytimes_articles(search_terms, start_time_cycle.strftime('%Y%m%d'), end_time_cycle.strftime('%Y%m%d'))
      end_time_cycle -= (step + 1.day)
      start_time_cycle -= (step + 1.day)
    end
  end

  def self.select_articles_from_database(permitted_params)
    # if timeframe given, find all articles that has the keywords in title, abstract, lead_paragraph, or keyword within the timeframe.
    if permitted_params[:start_time] && permitted_params[:end_time]
      keyword_search_result = self.joins(:keywords).where("
        articles.publication_time >= ? AND articles.publication_time <= ? AND keywords.name ~* ?",
        permitted_params[:start_time], permitted_params[:end_time],
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      title_search_result = self.where(
        "publication_time >= ? AND publication_time <= ? AND title ~* ?",
        permitted_params[:start_time], permitted_params[:end_time],
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      abstract_search_result = self.where(
        "publication_time >= ? AND publication_time <= ? AND abstract ~* ?",
        permitted_params[:start_time], permitted_params[:end_time],
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      lead_paragraph_search_result = self.where(
        "publication_time >= ? AND publication_time <= ? AND lead_paragraph ~* ?",
        permitted_params[:start_time], permitted_params[:end_time],
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      snippet_search_result = self.where(
        "publication_time >= ? AND publication_time <= ? AND snippet ~* ?",
        permitted_params[:start_time], permitted_params[:end_time],
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      return keyword_search_result | title_search_result | snippet_search_result | lead_paragraph_search_result | abstract_search_result

    else
      # if timeframe not given, find all articles that has the keywords in title, abstract, lead_paragraph, or keyword from all time
      keyword_search_result = self.joins(:keywords).where(
        "keywords.name ~* ?",
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      title_search_result = self.where(
        "title ~* ?",
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      abstract_search_result = self.where("
        abstract ~* ?",
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      lead_paragraph_search_result = self.where(
        "lead_paragraph ~* ?",
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      snippet_search_result = self.where(
        "snippet ~* ?",
        '\W' + "#{permitted_params[:search]}" + '\W'
      ).order(:publication_time)

      return keyword_search_result | title_search_result | snippet_search_result | lead_paragraph_search_result | abstract_search_result
    end
  end

  #define a function that cut the selected time period into 20 zones with equal length. the function will return an array of zones, each as a hash, with start_time, end_time, list of articles within the time zone, count of articles within the zone, and 'hotness' of the zone
  def self.divide_into_zones(articles)
    # set the start_time to be the publication_time of the latest article, and end_time to be the publication_time of the oldest one. Then
    begin_date = articles.last.publication_time
    end_date = articles.first.publication_time
    # the +1 is to make sure the last zone will include the newest article
    time_unit = (end_date - begin_date + 1) / 20

    zones = []
    for i in (0 .. 19)
      zones[i] = {
                  start_time: begin_date + time_unit * i,
                  end_time: begin_date + time_unit * (i + 1)}
      zones[i][:article_list] = articles.select { |article|
                  article.publication_time >= zones[i][:start_time] && article.publication_time < zones[i][:end_time]}
      zones[i][:count] = zones[i][:article_list].size
      zones[i][:keywords] = generate_keywords(zones[i][:article_list])
    end
    zones = self.calculate_hotness(zones)
    return zones
  end

  # defining a function that can calculate "hottest" of a zone, based on the number of articles it has comparing to the average, and to the max and min
  def self.calculate_hotness(zones)
    # find the max, min, average
    temp = zones.inject([0,100,0]) do |temp, zone|
      if temp[0] < zone[:count]
        temp[0] = zone[:count]
      end
      if temp[1] > zone[:count]
        temp[1] = zone[:count]
      end
      temp[2] += zone[:count]
      temp
    end
    hottest = temp[0]
    coldest = temp[1]
    total = temp[2]
    average = total/20.0
    #calculate hotness based on the count of articles in the zone, comparing to average, max, min
    zones.each do |zone|
      if zone[:count] > average
        zone[:hotness] = (5 + (zone[:count] - average) * 5 / (hottest - average)).round
      elsif zone[:count] < average
        zone[:hotness] = 5 - ((average - zone[:count]) * 5 / (average - coldest)).round
      elsif zone[:count] = average
        zone[:hotness] = 5
      end
    end
    return zones
  end

  # defining a method that takes in a zone or a selection of articles and returns top keywords
  def self.generate_keywords(articles)
    # creating an empty keyword collection for the given article. the key will be the keyword, and the value will be the sum of relevance of the keyword among all selected articles
    keywords_collection = {}
    articles.each do |article|
      article.keywords.each do |keyword|
        # iterate through all article and keyword pairs and try to find the keyword_analysis that connect them.
        corresponding_keyword_analysis = KeywordAnalysis.where("article_id = ? AND keyword_id = ?", article, keyword)
        unless corresponding_keyword_analysis.empty?
          if keywords_collection.keys.include?(keyword.name)
            keywords_collection["#{keyword.name}"] += corresponding_keyword_analysis.first.relevance
          else
            keywords_collection["#{keyword.name}"] = corresponding_keyword_analysis.first.relevance
          end
        end
      end
    end
    # rank the keyword and output in arry
    ranking_keyword = keywords_collection.sort_by {|keyword, relevance| relevance}
    result = []
    ranking_keyword.reverse!.each do |keyword_relevance|
      result << {keyword: keyword_relevance[0].to_s, relevance: keyword_relevance[1]}
    end
    return result
  end

  def self.analyze_articles(permitted_params)
    # selecting articles and sort them into chronological order
    articles = Article.select_articles_from_database(permitted_params).sort { |a, b| b.publication_time <=> a.publication_time }
    puts(articles.size)
    # if find any articles, divide the article into zones.
    if articles.any?
      result = {zones: Article.divide_into_zones(articles)}
      result[:keywords] = Article.generate_keywords(articles)
      result[:search_info] = {
        search_string: permitted_params[:search],
        start_time: articles.last.publication_time,
        end_time: articles.first.publication_time
      }
      puts(result[:zones].inject(0) {|sum, zone| sum + zone[:count]})
      # output the zones
      return result
    else
      # if no article found, nust render the html page
      return nil
    end
  end

end
