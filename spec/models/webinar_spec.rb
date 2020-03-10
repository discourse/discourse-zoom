# frozen_string_literal: true

require "rails_helper"

describe Webinar do
  fab!(:first_user) { Fabricate(:user) }
  fab!(:second_user) { Fabricate(:user) }
  fab!(:third_user) { Fabricate(:user) }
  fab!(:fourth_user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic, user: first_user) }
  let(:webinar) { Webinar.create(topic: topic, zoom_id: "123") }

  describe "unique zoom_id" do
    it 'does not create a duplicate' do
      webinar.save
      webinar_dupe = Webinar.create(topic: topic, zoom_id: "123")
      expect(webinar_dupe.save).to eq(false)
    end

    it 'does not validate uniqueness on nonzoom events' do
      webinarA = Webinar.create(topic: topic, zoom_id: "nonzoom")
      webinarA.save
      webinarB = Webinar.create(topic: topic, zoom_id: "nonzoom")
      expect(webinarB.save).to eq(true)
    end
  end

  describe ".sanitize_zoom_id" do
    it 'removes spaces and dashes' do
      id = ' 342-265-6531'
      expect(Webinar.sanitize_zoom_id(id)).to eq('3422656531')
    end
  end

  describe 'users' do
    before do
      webinar.webinar_users.create(user: first_user, type: :attendee)
      webinar.webinar_users.create(user: second_user, type: :panelist)
      webinar.webinar_users.create(user: third_user, type: :host)
      webinar.webinar_users.create(user: fourth_user, type: :attendee)
    end
    describe "#attendees" do
      it "gets attendees" do
        attendees = webinar.attendees
        expect(attendees.count).to eq(2)
        expect(attendees.include? first_user).to eq(true)
        expect(attendees.include? fourth_user).to eq(true)
      end
    end
    describe "#panelists" do
      it "gets panelists" do
        panelists = webinar.panelists
        expect(panelists.count).to eq(1)
        expect(panelists.first).to eq(second_user)
      end
    end
    describe "#host" do
      it "gets host" do
        expect(webinar.host).to eq(third_user)
      end
    end
  end

  describe "update" do
    it "publishes to message_bus if status changed" do
      MessageBus.expects(:publish).with("/zoom/webinars/#{webinar.id}", status: "started")
      webinar.update(status: :started)
    end

    it "does not publishes to message_bus if status is unchanged" do
      MessageBus.expects(:publish).never
      webinar.update(duration: 120)
    end
  end

end
