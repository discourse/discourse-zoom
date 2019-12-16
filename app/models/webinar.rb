class Webinar < ActiveRecord::Base
  belongs_to :topic
  belongs_to :host, class_name: 'User'
end
