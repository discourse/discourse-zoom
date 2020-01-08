# frozen_string_literal: true
class Webinar < ActiveRecord::Base

  enum approval_type: { automatic: 0, manual: 1, no_registration: 2 }

  has_many :webinar_users
  has_many :users, through: :webinar_users
  belongs_to :topic
  belongs_to :host, class_name: 'User'

  def self.sanitize_zoom_id(dirty_id)
    dirty_id.to_s.strip.gsub('-', '')
  end

  def attendees
    users.joins(:webinar_users)
      .where("webinar_users.type = #{WebinarUser.types[:attendee]} AND webinar_users.registration_status = #{WebinarUser.registration_statuses[:approved]}").uniq
  end

  def speakers
    users.joins(:webinar_users).where("webinar_users.type = #{WebinarUser.types[:speaker]}").uniq
  end

  def host
    users.joins(:webinar_users).where("webinar_users.type = #{WebinarUser.types[:host]}").first
  end
end
