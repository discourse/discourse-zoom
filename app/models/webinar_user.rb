class WebinarUser < ActiveRecord::Base
  enum type: [:attendee, :panelist, :host]

  validates :type, presence: true, inclusion: { in: types.keys }
  validates :user_id, presence: true
  validates :webinar_id, presence: true

  belongs_to :user
  belongs_to :webinar
end
