class ArticlesController < ApplicationController
  def index
  end

  def search
    # get the result
    @result = Article.analyze_articles(permit_params)
    if current_user
      @result[:user_id] = current_user.id
    end
    if @result
      respond_to do |format|
        # format.html
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

end
