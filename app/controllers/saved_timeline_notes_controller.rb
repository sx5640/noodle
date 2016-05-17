class SavedTimelineNotesController < ApplicationController
  def create
    new_note = SavedTimeline.find(saved_timeline_note_params[:saved_timeline_id]).saved_timeline_notes.new(saved_timeline_note_params)
    if new_note.save
      render json: { success: true, action: "save timeline note"}
    else
      render json: { success: false, action: "save timeline note"}
    end
  end

  def update
    @note = SavedTimelineNote.find(params[:id])
    if @note.update_attributes(saved_timeline_note_params)
      render json: { success: true, action: "update timeline note"}
    else
      render json: { success: false, action: "update timeline note"}
    end
  end

  def destroy
    @note = SavedTimelineNote.find(params[:id])
    if @note.destroy
      render json: { success: true, action: "delete timeline note" }
    else
      render json: { success: false, action: "delete timeline note" }
    end
  end

  private
  def saved_timeline_note_params
    params.permit(:saved_timeline_id, :text, :zone_num)
  end
end
