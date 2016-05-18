class ArticlesController < ApplicationController
  def index
  end

  def search
    # get the result
    @result = Article.analyze_articles(permit_params)
    if current_user
      @result[:user] = {user_id: current_user.id}
      if SavedTimeline.joins(:user).where("
        users.id = ? AND saved_timelines.search_string = ? AND saved_timelines.start_time = ? AND saved_timelines.end_time = ?",
        current_user.id, @result[:search_info][:search_string], @result[:search_info][:start_time],
        @result[:search_info][:end_time]
        ).empty?
        @result[:user][:saved_this_timeline] = false
      else
        @result[:user][:saved_this_timeline] = true
      end
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
    permitted_params = params.permit(:search, :start_time, :end_time)
    # if there is a timeframe, clean up the timeframe and turn into DateTime object
    if permitted_params[:start_time] && permitted_params[:end_time]
      permitted_params[:start_time] = DateTime.parse(
        permitted_params[:start_time])
      permitted_params[:end_time] = DateTime.parse(
        permitted_params[:end_time])
    end
    return permitted_params
  end

end
