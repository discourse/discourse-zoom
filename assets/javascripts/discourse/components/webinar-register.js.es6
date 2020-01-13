import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { or } from "@ember/object/computed";

export default Component.extend({
  loading: false,
  registrationSuccessful: false,
  NO_REGISTRATION: "no_registration",
  registered: or("isHost", "isPanelist", "isAttendee"),

  // TODO: Handle during event, after event

  @discourseComputed("currentUser", "webinar.attendees")
  isAttendee(user, attendees) {
    for (let attendee of attendees) {
      if (attendee.id === user.id) {
        return true;
      }
    }
    return false;
  },

  @discourseComputed("currentUser", "webinar.host")
  isHost(user, host) {
    return user.id === host.id;
  },

  @discourseComputed("currentUser", "webinar.panelists")
  isPanelist(user, panelists) {
    for (let panelist of panelists) {
      if (panelist.id === user.id) {
        return true;
      }
    }
    return false;
  },

  @discourseComputed(
    "currentUser",
    "webinar.host",
    "webinar.panelists",
    "webinar.attendees"
  )
  canUnregister(user, host, panelists, attendees) {
    return this.isAttendee && this.registered;
  },

  @discourseComputed(
    "currentUser",
    "webinar.{id,starts_at,ends_at,approval_type}"
  )
  userCanRegister(user, webinar) {
    return webinar.approval_type !== this.NO_REGISTRATION && !this.registered;
  },

  toggleRegistration(registering) {
    const method = registering ? "PUT" : "DELETE";
    this.set("loading", true);
    ajax(
      `/zoom/webinars/${this.webinar.zoom_id}/attendees/${this.currentUser.username}`,
      { type: method }
    )
      .then(response => {
        this.store.find("webinar", this.webinar.zoom_id).then(webinar => {
          this.set("webinar", webinar);
        });
        this.set("loading", false);
      })
      .finally(() => this.set("loading", false));
  },

  actions: {
    register() {
      this.toggleRegistration(true);
    },

    unregister() {
      this.toggleRegistration(false);
    }
  }
});
