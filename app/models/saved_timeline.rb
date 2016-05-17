class SavedTimeline < ActiveRecord::Base
  belongs_to :user
  has_many :saved_timeline_notes
end
