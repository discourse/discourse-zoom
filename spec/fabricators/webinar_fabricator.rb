# frozen_string_literal: true

require "rails_helper"

Fabricator(:webinar) do
  title "Test webinar"
  starts_at 6.hours.from_now
  ends_at 7.hours.from_now
  duration 60
  zoom_host_id 'a1a1k1k30291'
end
