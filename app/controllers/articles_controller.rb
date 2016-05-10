class ArticlesController < ApplicationController
  def index
  end

  def search
    @articles = article_selector
    unless @articles
      start_time = @articles.first.publication_time
      end_time = @articles.last.publication_time
    end

    respond_to do |format|
      format.html
      format.json { render json: @articles.to_json }
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

  def zoner(articles, start_time, end_time)
    timeline = []
  end
end
