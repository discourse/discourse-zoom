# frozen_string_literal: true

class WebinarSerializer < ApplicationSerializer
  has_many :attendees, serializer: UserSerializer
  has_one :host, serializer: UserSerializer
  has_many :speakers, serializer: UserSerializer

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
    :attendees,
    :host,
    :speakers,
    :attendees

  def require_password
    !object.password.blank?
  end

end

