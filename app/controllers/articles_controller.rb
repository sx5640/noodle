class ArticlesController < ApplicationController
  def index
  end

  def search
    @articles = article_selector.sort { |a, b| b.publication_time <=> a.publication_time }
    puts(@articles.size)
    if @articles
      start_time = @articles.last.publication_time
      end_time = @articles.first.publication_time
      @result = zoner(@articles, start_time, end_time)
      puts(@result.inject(0) {|sum, zone| sum + zone[:count]})
    end
    respond_to do |format|
      format.html
      format.json { render json: @result }
    end
  end

  private

  def article_selector
    permit_params = params.permit(:search, start_time: ["(1i)", "(2i)", "(3i)", "(4i)", "(5i)"], end_time: ["(1i)", "(2i)", "(3i)", "(4i)", "(5i)"])
    if permit_params[:start_time] && permit_params[:end_time]
      permit_params[:start_time] = DateTime.new(
                          permit_params[:start_time]["(1i)"].to_i,
                          permit_params[:start_time]["(2i)"].to_i,
                          permit_params[:start_time]["(3i)"].to_i,
                          permit_params[:start_time]["(4i)"].to_i,
                          permit_params[:start_time]["(5i)"].to_i)
      permit_params[:end_time] = DateTime.new(
                          permit_params[:end_time]["(1i)"].to_i,
                          permit_params[:end_time]["(2i)"].to_i,
                          permit_params[:end_time]["(3i)"].to_i,
                          permit_params[:end_time]["(4i)"].to_i,
                          permit_params[:end_time]["(5i)"].to_i)
      result = Article.joins(:keywords).where("articles.publication_time >= ? AND articles.publication_time <= ? AND keywords.name LIKE ?", permit_params[:start_time], permit_params[:end_time], permit_params[:search]).order(:publication_time)
      result += Article.where("publication_time >= ? AND publication_time <= ? AND title LIKE ?", permit_params[:start_time], permit_params[:end_time], "%#{permit_params[:search]}%").order(:publication_time)

    else
      result = Article.joins(:keywords).where("keywords.name = ?", permit_params[:search]).order(:publication_time)
      result += Article.where("title LIKE ?", "%#{permit_params[:search]}%").order(:publication_time)
    end
  end

  #define a function that cut the selected time period into 20 zones with equal length. the function will return an array of zones, each as a hash, with start_time, end_time, list of articles within the time zone, count of articles within the zone, and 'hotness' of the zone
  def zoner(articles, begin_date, end_date)
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
    end
    zones = hotness(zones)
    return zones
  end
  # defining a function that can calculate "hottest" of a zone, based on the number of articles it has comparing to the average, and to the max and min
  def hotness(zones)
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

  def method
    #code
  end
end
