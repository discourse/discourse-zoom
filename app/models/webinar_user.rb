# frozen_string_literal: true
class WebinarUser < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  enum type: { attendee: 0, speaker: 1, host: 2 }
  enum registration_status: { pending: 0, approved: 1, rejected: 2 }

  validates :type, presence: true, inclusion: { in: types.keys }
  validates :registration_status, presence: true, inclusion: { in: registration_statuses.keys }
  validates :webinar_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :webinar_id,
                                                    message: "user can only be registered once" }

  belongs_to :user
  belongs_to :webinar
end
