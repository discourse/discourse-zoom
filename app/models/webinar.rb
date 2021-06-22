# frozen_string_literal: true

class Webinar < ActiveRecord::Base

  enum approval_type: { automatic: 0, manual: 1, no_registration: 2 }
  enum status: { pending: 0, started: 1, ended: 2 }

  has_many :webinar_users
  has_many :users, through: :webinar_users
  belongs_to :topic

  validates :zoom_id, presence: true
  validates :zoom_id, uniqueness: { message: :webinar_in_use }, unless: :non_zoom_event?

  validates :topic_id, presence: true

  after_commit :notify_status_update, on: :update

  ZOOM_ATTRIBUTE_MAP = {
    id: :zoom_id,
    topic: :title,
    start_time: :starts_at,
  }.freeze

  def self.sanitize_zoom_id(dirty_id)
    dirty_id.to_s.strip.gsub('-', '')
  end

  def attendees
    users.joins(:webinar_users).where("webinar_users.type = #{WebinarUser.types[:attendee]}").uniq
  end

  def panelists
    users.joins(:webinar_users).where("webinar_users.type = #{WebinarUser.types[:panelist]}").uniq
  end

  def host
    users.joins(:webinar_users).where("webinar_users.type = #{WebinarUser.types[:host]}").first
  end

  def update_from_zoom(zoom_attributes)
    update(convert_attributes_from_zoom(zoom_attributes))
  end

  def convert_attributes_from_zoom(zoom_attributes)
    zoom_attributes = (zoom_attributes[:settings] || {}).merge(zoom_attributes.except(:settings)).to_h.deep_symbolize_keys

    zoom_attributes[:approval_type] = zoom_attributes[:approval_type].to_i if zoom_attributes[:approval_type]
    if zoom_attributes[:start_time] || zoom_attributes[:duration]
      zoom_attributes[:start_time] = zoom_attributes[:start_time] || starts_at.to_s
      zoom_attributes[:duration] = zoom_attributes[:duration] || duration
      zoom_attributes[:ends_at] = (DateTime.parse(zoom_attributes[:start_time]) + zoom_attributes[:duration].to_i.minutes).to_s
    end

    converted_attributes = {}

    zoom_attributes.each do |key, value|
      converted_key = ZOOM_ATTRIBUTE_MAP[key] || key
      converted_attributes[converted_key] = value if has_attribute? converted_key
    end
    converted_attributes
  end

  def non_zoom_event?
    zoom_id == "nonzoom"
  end

  private

  def notify_status_update
    return if previous_changes["status"].nil?

    MessageBus.publish("/zoom/webinars/#{id}", status: status)
  end
end
