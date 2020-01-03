# frozen_string_literal: true
class Webinar < ActiveRecord::Base

  enum approval_type: [:automatic, :manual, :no_registration]

  has_many :webinar_users
  has_many :users, through: :webinar_users
  belongs_to :topic
  belongs_to :host, class_name: 'User'

  def self.sanitize_zoom_id(dirty_id)
    dirty_id.to_s.strip.gsub('-', '')
  end
end
