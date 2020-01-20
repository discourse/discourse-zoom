# frozen_string_literal: true

class WebinarSerializer < ApplicationSerializer
  has_one :host, serializer: HostSerializer, embed: :objects
  has_many :attendees, serializer: BasicUserSerializer, embed: :objects
  has_many :panelists, serializer: BasicUserSerializer, embed: :objects

  attributes :topic_id,
    :id,
    :zoom_id,
    :title,
    :starts_at,
    :ends_at,
    :duration,
    :zoom_host_id,
    :require_password,
    :host_video,
    :panelists_video,
    :approval_type,
    :enforce_login,
    :registrants_restrict_number,
    :meeting_authentication,
    :on_demand,
    :join_url,
    :status,
    :video_url

  def require_password
    !object.password.blank?
  end
end
