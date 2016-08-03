class ArticlesController < ApplicationController
  def index
  end

  def search
    # check cache for the search params
    redis_key = "search:#{permit_params[:search]}; start_time:#{permit_params[:start_time]}; end_time:#{permit_params[:end_time]}"
    cache = $redis.get(redis_key)
    if cache
      @result = JSON.parse(cache)
      # the line commented out below gives an option to renew the expiration time everytime it is searched
      # $redis.expire(redis_key, 1.hour.to_i)
    else
      # do a new search and save the result in cache, expires in 1 hour
      @result = Article.analyze_articles(permit_params)
      $redis.set(redis_key, @result.to_json)
      $redis.expire(redis_key, 1.hour.to_i)
    end
    if current_user
      @result[:user] = {user_id: current_user.id}
      if @result
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
    end
    respond_to do |format|
      # format.html
      format.json { render json: @result }
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
