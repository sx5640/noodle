class ArticlesController < ApplicationController
  def index
  end

  def search
    # selecting_articles and sort them into chronological order
    @articles = selecting_articles(permit_params).sort { |a, b| b.publication_time <=> a.publication_time }
    puts(@articles.size)
    # if find any articles, set the start_time to be the publication_time of the latest article, and end_time to be the publication_time of the oldest one. Then divide the article into zones.
    if @articles
      start_time = @articles.last.publication_time
      end_time = @articles.first.publication_time
      @result = {zones: dividing_into_zones(@articles, start_time, end_time)}
      @result[:keywords] = getting_keyword(@articles)
      puts(@result[:zones].inject(0) {|sum, zone| sum + zone[:count]})
      # output the zones
      respond_to do |format|
        format.html
        format.json { render json: @result }
      end
    else
      # if no article found, nust render the html page
      respond_to do |format|
        format.html
      end
    end
  end

  private
  # defining a method to clean up the params
  def permit_params
    # permit only search terms and time frames
    permitted_params = params.permit(:search, start_time: ["(1i)", "(2i)", "(3i)", "(4i)", "(5i)"], end_time: ["(1i)", "(2i)", "(3i)", "(4i)", "(5i)"])
    # if there is a timeframe, clean up the timeframe and turn into DateTime object
    if permitted_params[:start_time] && permitted_params[:end_time]
      permitted_params[:start_time] = DateTime.new(
        permitted_params[:start_time]["(1i)"].to_i,
        permitted_params[:start_time]["(2i)"].to_i,
        permitted_params[:start_time]["(3i)"].to_i,
        permitted_params[:start_time]["(4i)"].to_i,
        permitted_params[:start_time]["(5i)"].to_i
      )
      permitted_params[:end_time] = DateTime.new(
        permitted_params[:end_time]["(1i)"].to_i,
        permitted_params[:end_time]["(2i)"].to_i,
        permitted_params[:end_time]["(3i)"].to_i,
        permitted_params[:end_time]["(4i)"].to_i,
        permitted_params[:end_time]["(5i)"].to_i
      )
    end
    return permitted_params
  end
  # defining a method that select articles based on the data given from the params
  def selecting_articles(permitted_params)
    # if timeframe given, find all articles that has the keywords in title, abstract, lead_paragraph, or keyword within the timeframe.
    if permitted_params[:start_time] && permitted_params[:end_time]
      keyword_search_result = Article.joins(:keywords).where("
        articles.publication_time >= ? AND articles.publication_time <= ? AND keywords.name LIKE ?",
        permitted_params[:start_time], permitted_params[:end_time], "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      title_search_result = Article.where(
        "publication_time >= ? AND publication_time <= ? AND title LIKE ?",
        permitted_params[:start_time], permitted_params[:end_time], "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      abstract_search_result = Article.where(
        "publication_time >= ? AND publication_time <= ? AND abstract LIKE ?",
        permitted_params[:start_time], permitted_params[:end_time], "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      lead_paragraph_search_result = Article.where(
        "publication_time >= ? AND publication_time <= ? AND lead_paragraph LIKE ?",
        permitted_params[:start_time], permitted_params[:end_time], "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      snippet_search_result = Article.where(
        "publication_time >= ? AND publication_time <= ? AND snippet LIKE ?",
        permitted_params[:start_time], permitted_params[:end_time], "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      return keyword_search_result | title_search_result | snippet_search_result | lead_paragraph_search_result | abstract_search_result

    else
      # if timeframe not given, find all articles that has the keywords in title, abstract, lead_paragraph, or keyword from all time
      keyword_search_result = Article.joins(:keywords).where(
        "keywords.name LIKE ?", "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      title_search_result = Article.where(
        "title LIKE ?", "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      abstract_search_result = Article.where("
        abstract LIKE ?", "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      lead_paragraph_search_result = Article.where(
        "lead_paragraph LIKE ?", "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      snippet_search_result = Article.where(
        "snippet LIKE ?", "%#{permitted_params[:search]}%"
      ).order(:publication_time)

      return keyword_search_result | title_search_result | snippet_search_result | lead_paragraph_search_result | abstract_search_result
    end
  end

  #define a function that cut the selected time period into 20 zones with equal length. the function will return an array of zones, each as a hash, with start_time, end_time, list of articles within the time zone, count of articles within the zone, and 'hotness' of the zone
  def dividing_into_zones(articles, begin_date, end_date)
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
      zones[i][:keywords] = getting_keyword(zones[i][:article_list])
    end
    zones = calculating_hotness(zones)
    return zones
  end
  # defining a function that can calculate "hottest" of a zone, based on the number of articles it has comparing to the average, and to the max and min
  def calculating_hotness(zones)
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
    #calculate hottness based on the count of articles in the zone, comparing to average, max, min
    zones.each do |zone|
      if zone[:count] > average
        zone[:hottness] = (5 + (zone[:count] - average) * 5 / (hottest - average)).round
      elsif zone[:count] < average
        zone[:hottness] = 5 - ((average - zone[:count]) * 5 / (average - coldest)).round
      elsif zone[:count] = average
        zone[:hottness] = 5
      end
    end
    return zones
  end
  # defining a method that takes in a zone or a selection of articles and returns top keywords
  def getting_keyword(articles)
    # creating an empty keyword collection for the given article. the key will be the keyword, and the value will be the sum of relevance of the keyword among all selected articles
    keywords_collection = {}
    articles.each do |article|
      article.keywords.each do |keyword|
        # iterate through all article and keyword pairs and try to find the keyword_analysis that connect them.
        corresponding_keyword_analysis = KeywordAnalysis.where("article_id = ? AND keyword_id = ?", article, keyword)
        unless corresponding_keyword_analysis.empty?
          if keywords_collection.keys.include?(keyword)
            keywords_collection["#{keyword}"] += corresponding_keyword_analysis.first.relevance
          else
            keywords_collection["#{keyword}"] = corresponding_keyword_analysis.first.relevance
          end
        end
      end
    end
    # rank the keyword and output in arry
    ranking_keyword = keywords_collection.sort_by {|keyword, relevance| relevance}
    result = []
    ranking_keyword.each do |keyword_relevance|
      result << {keyword: keyword_relevance[0].to_s, relevance: keyword_relevance[1]}
    end
    return result
  end
end
