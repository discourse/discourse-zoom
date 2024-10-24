# frozen_string_literal: true
class WebinarUser < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  enum type: { attendee: 0, panelist: 1, host: 2 }

  validates :type, presence: true, inclusion: { in: types.keys }
  validates :webinar_id, presence: true
  validates :user_id,
            presence: true,
            uniqueness: {
              scope: :webinar_id,
              message: "user can only be registered once",
            }

  belongs_to :user
  belongs_to :webinar
end

# == Schema Information
#
# Table name: webinar_users
#
#  id         :bigint           not null, primary key
#  user_id    :integer
#  webinar_id :bigint
#  type       :integer
#
