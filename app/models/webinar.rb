# frozen_string_literal: true
class Webinar < ActiveRecord::Base

  has_many :webinar_users
  has_many :users, through: :webinar_users
  belongs_to :topic
  belongs_to :host, class_name: 'User'
end
