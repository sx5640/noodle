class ArticlesController < ApplicationController
  def index
  end

  def search
    @articles = article_selector
    unless @articles
      start_time = @articles.first.publication_time
      end_time = @articles.last.publication_time
    end
  end

  private

  def article_selector
    permit_params = params.permit(:start_time, :end_time, :search)
    binding.pry
    permit_params[:start_time] = DateTime.new(permit_params[:start_time]["(1i)"].to_i,
                        permit_params[:start_time]["(2i)"].to_i,
                        permit_params[:start_time]["(3i)"].to_i,
                        permit_params[:start_time]["(4i)"].to_i,
                        permit_params[:start_time]["(5i)"].to_i)
    permit_params[:end_time] = DateTime.new(permit_params[:end_time]["(1i)"].to_i,
                        permit_params[:end_time]["(2i)"].to_i,
                        permit_params[:end_time]["(3i)"].to_i,
                        permit_params[:end_time]["(4i)"].to_i,
                        permit_params[:end_time]["(5i)"].to_i)
    article_selected = []
    if permit_params[:start_time] && permit_params[:end_time]
      Article.joins('keywords').where("articles.publication_time >= ? AND articles.publication_time <= ? and keywords.name = ?", permit_params[:start_time], permit_params[:end_time], permit_params[:search]).order(:publication_time)
      binding.pry
    else
      Article.joins('keywords').where("keywords.name = ?", permit_params[:search]).order(:publication_time)
      binding.pry
    end
    return article_selected
  end

  def article_density(articles, start_time, end_time)
    timeline = []
  end
end
