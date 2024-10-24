# frozen_string_literal: true

class ZoomWebinarWebhookEvent < ActiveRecord::Base
end

# == Schema Information
#
# Table name: zoom_webinar_webhook_events
#
#  id             :bigint           not null, primary key
#  event          :string
#  payload        :text
#  webinar_id     :integer
#  zoom_timestamp :bigint
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
