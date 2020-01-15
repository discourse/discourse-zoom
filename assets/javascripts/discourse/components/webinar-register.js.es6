import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { or, equal } from "@ember/object/computed";

const STARTED = "started";

export default Component.extend({
  loading: false,
  registrationSuccessful: false,
  registered: or("isHost", "isPanelist", "isAttendee"),
  webinarStarted: equal("webinar.status", STARTED),

  // TODO: Handle during event, after event

  @discourseComputed("currentUser", "webinar.attendees")
  isAttendee(user, attendees) {
    if (attendees) {
      for (let attendee of attendees) {
        if (attendee.id === user.id) {
          return true;
        }
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

  @discourseComputed("webinar.attendees")
  canUnregister(attendees) {
    return this.isAttendee && this.registered;
  },

  @discourseComputed("webinar.{id,starts_at,ends_at}")
  userCanRegister(webinar) {
    return !this.isAttendee && !this.registered;
  },

  toggleRegistration(registering) {
    const method = registering ? "PUT" : "DELETE";
    this.set("loading", true);
    return ajax(
      `/zoom/webinars/${this.webinar.id}/attendees/${this.currentUser.username}`,
      { type: method }
    )
      .then(response => {
        this.store.find("webinar", this.webinar.id).then(webinar => {
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
    },

    joinSDK() {
      const url = `/zoom/webinars/${this.webinar.id}/sdk`;

      if (this.registered) {
        window.location.href = url;
      } else {
        this.toggleRegistration(true).then(response => {
          console.log(response);
          window.location.href = url;
        });
      }
    }
  }
});
