class SavedTimelinesController < ApplicationController
  def create
    new_saved_timeline = current_user.saved_timelines.new(saved_timeline_params)
    if new_saved_timeline.save
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def destroy
    @saved_timeline = SavedTimeline.find(params[:id])
    if @saved_timeline.destroy
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def show
    saved_timeline = SavedTimeline.find(params[:id])
    @result = Article.analyze_articles(saved_timeline)
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
  def saved_timeline_params
    # permit only search terms and time frames
    permitted_params = params.permit(:keyword, :start_time, :end_time)
    permitted_params[:start_time] = permitted_params[:start_time].to_datetime
    permitted_params[:end_time] = permitted_params[:end_time].to_datetime
    return permitted_params
  end
end
