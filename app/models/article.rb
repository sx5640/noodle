require 'article_mixins/zone.rb'

class Article < ActiveRecord::Base
  has_many :keyword_analyses
  has_many :keywords, through: :keyword_analyses
  has_many :saved_timelines

  extend ArticleMixins::Zone
  # defining a method dedicated to get articles from NYTimes
  def self.create_articles(entry)
      # select data from each article where the JSON attributes has the same name with out Article class object.
      # everything from the JSON taht is not selected cannot be saved directly into database and needed clean up
    unless self.find_by(web_url: entry['web_url'])
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
      Keyword.get_watson_keywords(article)
      # Keyword.get_nytimes_keywords(entry, article)
    end
  end

  def self.get_nytimes_articles(search_terms, begin_date, end_date)
    articles = []
    search_terms = search_terms.split(" ").join("%20")
    # loop through page 0 to page 100
    for i in (0 .. 100)
      # get 10 articles with given keyword, timeframe and page #
      response = JSON.parse(
      Typhoeus.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{search_terms}&page=#{i}&begin_date=#{begin_date}&end_date=#{end_date}&sort=newest&api-key=#{Rails.application.secrets.nytimes_key}").body)
      puts(i)
      # if no article returns, break the loop
      if response["response"]["docs"].empty?
        break
      else
        # iterate through the 10 articles get from each call, and clean up the data
        articles << response["response"]["docs"]


        # response["response"]["docs"].each do |entry|
        threads = []
        num_of_threads = 4
        num_of_threads.times do |t|
          threads[t] = Thread.new do
            if response["response"]["docs"][t]
              self.create_articles(response["response"]["docs"][t])
              if response["response"]["docs"][t+4]
                self.create_articles(response["response"]["docs"][t+4])
                if response["response"]["docs"][t+8]
                  self.create_articles(response["response"]["docs"][t+8])
                end
              end
            end
          end
        end
        threads.each {|t| t.join}
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
      puts "#{search_terms}"
      puts "#{start_time_cycle} To #{end_time_cycle}"
      articles = Article.get_nytimes_articles(search_terms, start_time_cycle.strftime('%Y%m%d'), end_time_cycle.strftime('%Y%m%d'))
      end_time_cycle -= (step + 1.day)
      start_time_cycle -= (step + 1.day)
    end
  end

  def self.select_articles_from_database(permitted_params)
    # if timeframe given, find all articles that has the keywords in title, abstract, lead_paragraph, or keyword within the timeframe.
    search_items = permitted_params[:search].split("|")

    selected_articles = []
    # search in database with keywords.the \y regex means word boundary
    search_items.each do |search_item|
      if permitted_params[:start_time] && permitted_params[:end_time]
        keyword_search_result = self.joins(:keywords).where("
          articles.publication_time >= ? AND articles.publication_time <= ? AND keywords.name ~* ?",
          permitted_params[:start_time], permitted_params[:end_time],
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        title_search_result = self.where(
          "publication_time >= ? AND publication_time <= ? AND title ~* ?",
          permitted_params[:start_time], permitted_params[:end_time],
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        abstract_search_result = self.where(
          "publication_time >= ? AND publication_time <= ? AND abstract ~* ?",
          permitted_params[:start_time], permitted_params[:end_time],
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        lead_paragraph_search_result = self.where(
          "publication_time >= ? AND publication_time <= ? AND lead_paragraph ~* ?",
          permitted_params[:start_time], permitted_params[:end_time],
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        snippet_search_result = self.where(
          "publication_time >= ? AND publication_time <= ? AND snippet ~* ?",
          permitted_params[:start_time], permitted_params[:end_time],
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        selected_articles << (keyword_search_result | title_search_result | snippet_search_result | lead_paragraph_search_result | abstract_search_result)

      else
        # if timeframe not given, find all articles that has the keywords in title, abstract, lead_paragraph, or keyword from all time
        keyword_search_result = self.joins(:keywords).where(
          "keywords.name ~* ?",
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        title_search_result = self.where(
          "title ~* ?",
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        abstract_search_result = self.where("
          abstract ~* ?",
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        lead_paragraph_search_result = self.where(
          "lead_paragraph ~* ?",
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        snippet_search_result = self.where(
          "snippet ~* ?",
          '\y' + "#{search_item}" + '\y'
        ).order(:publication_time)

        selected_articles << (keyword_search_result | title_search_result | snippet_search_result | lead_paragraph_search_result | abstract_search_result)
      end
    end

    output_articles = selected_articles.inject {|result, e| result - (result - e) }

    return output_articles.uniq.sort { |a, b| a[:publication_time] <=> b[:publication_time] }

  end

  def self.generate_keywords(articles)
    # creating an empty keyword collection for the given article. the key will be the keyword, and the value will be the sum of relevance of the keyword among all selected articles
    keywords_collection = {}
    articles.each do |article|
      article.keyword_analyses.each do |keyword_analysis|
        # iterate through all article and keyword pairs and try to find the keyword_analysis that connect them.
        keyword = keyword_analysis.keyword
        if keywords_collection.keys.include?(keyword.name)
          keywords_collection["#{keyword.name}"] += keyword_analysis.relevance
        else
          keywords_collection["#{keyword.name}"] = keyword_analysis.relevance
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
    articles = Article.select_articles_from_database(permitted_params)
    puts(articles.size)
    # if find any articles, divide the article into zones.
    if articles.any?
      article_count = Article.count_articles(articles)
      result = {
        article_count: article_count[:data],
        zones: Article.divide_into_zones_from_peak(articles, article_count),
        keywords: Article.generate_keywords(articles),
        search_info: {
          search_string: permitted_params[:search],
          start_time: articles.last.publication_time,
          end_time: articles.first.publication_time
        }
      }
      puts(result[:zones].inject(0) {|sum, zone| sum + zone[:count]})
      # output the zones
    else
      result = {
        search_info: {
          search_string: permitted_params[:search]
        }
      }
    end
    return result
  end

  # this is a method that used to write article_count into txt file, then read by python script
  def self.write_txt(permitted_params)
    articles = Article.select_articles_from_database(permitted_params).sort { |a, b| b.publication_time <=> a.publication_time }
    puts(articles.length)

    begin_date = articles.last.publication_time
    end_date = articles.first.publication_time
    puts(begin_date)
    puts(end_date)

    step = 2.week

    i = 0
    if File.exist?("python/#{permitted_params[:search]}_2week.txt")
      File.delete("python/#{permitted_params[:search]}_2week.txt")
    end
    File.new("python/#{permitted_params[:search]}_2week.txt", "w+")
    sum = 0
    while begin_date + i*step <= end_date + step - 1.day
      articles_in_unit = articles.select { |article|
      article.publication_time >= begin_date + i*step &&
      article.publication_time < begin_date + (i+1)*step}
      write_in = "#{sprintf("%03d", i)}    #{sprintf("%03d", articles_in_unit.length)}\n"
      open("python/#{permitted_params[:search]}_2week.txt", 'a') { |f|
        f.puts write_in
      }
      i += 1
      sum += sprintf("%03d", articles_in_unit.length).to_i
    end
    puts(sum)
  end

  def self.get_guardian_articles(search_terms, begin_date, end_date)
    articles = []
    search_terms = search_terms.split(" ").join("%20")
    # loop through page 0 to page 100
    for i in (0 .. 100)
      # get 10 articles with given keyword, timeframe and page #
      response = JSON.parse(
      Typhoeus.get("http://api.nytimes.com/svc/search/v2/articlesearch.json?q=#{search_terms}&page=#{i}&begin_date=#{begin_date}&end_date=#{end_date}&sort=newest&api-key=#{Rails.application.secrets.nytimes_key}").body)
      puts(i)
      # if no article returns, break the loop
      if response["response"]["docs"].empty?
        break
      else
        # iterate through the 10 articles get from each call, and clean up the data
        articles << response["response"]["docs"]


        # response["response"]["docs"].each do |entry|
        threads = []
        num_of_threads = 4
        num_of_threads.times do |t|
          threads[t] = Thread.new do
            if response["response"]["docs"][t]
              self.create_articles(response["response"]["docs"][t])
              if response["response"]["docs"][t+4]
                self.create_articles(response["response"]["docs"][t+4])
                if response["response"]["docs"][t+8]
                  self.create_articles(response["response"]["docs"][t+8])
                end
              end
            end
          end
        end
        threads.each {|t| t.join}
      end
    end
    return articles
  end

end
