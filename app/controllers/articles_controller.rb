class ArticlesController < ApplicationController
  def index
  end

  def show
    @articles = article_selector
    start_time = articles.first.publication_time
    end_time = articles.last.publication_time
  end

  private

  def article_selector
    params.permit(:start_time, :end_time, :search)
    article_selected = []
    if params[:start_time] && params[:end_time]
      Article.all.where("publication_time >= ? AND publication_time <= ?", params[:start_time], params[:end_time]).order(:publication_time).each do |article|
        if article.keywords.where(name: params[:search])
          article_selected << article
        end
      end
    else
      Article.all.order(:publication_time).each do |article|
        if article.keywords.where(name: params[:search])
          article_selected << article
        end
      end
    end
    return article_selected
  end

  def article_density(articles, start_time, end_time)
    timeline = []
  end
end
