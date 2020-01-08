# frozen_string_literal: true
class Webinar < ActiveRecord::Base

  enum approval_type: { automatic: 0, manual: 1, no_registration: 2 }

  has_many :webinar_users
  has_many :users, through: :webinar_users
  belongs_to :topic
  belongs_to :host, class_name: 'User'

  ZOOM_ATTRIBUTE_MAP = {
    id: :zoom_id,
    topic: :title,
    start_time: :starts_at,
    duration: :duration,

  }.freeze

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

  def update_from_zoom(zoom_attributes)
    new_attributes = (zoom_attributes[:settings] || {}).merge(zoom_attributes.except(:settings)).deep_symbolize_keys

    if new_attributes[:start_time] || new_attributes[:duration]
      puts "time changed"
      new_attributes[:start_time] = new_attributes[:start_time] || starts_at.to_s
      new_attributes[:duration] = new_attributes[:duration] || duration
      new_attributes[:ends_at] = (DateTime.parse(new_attributes[:start_time]) + new_attributes[:duration].to_i.minutes).to_s
    end

    puts new_attributes.inspect

    # update(

    # )
  end
end
