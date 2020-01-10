import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";

export default Component.extend({
  loading: false,
  registrationSuccessful: false,
  NO_REGISTRATION: "no_registration",

  // TODO: Handle during event, after event

  @discourseComputed(
    "currentUser",
    "webinar.attendees",
    "registrationSuccessful"
  )
  registered(user, attendees, registrationSuccessful) {
    if (registrationSuccessful) return true;

    for (let attendee of attendees) {
      if (attendee.id === user.id) {
        return true;
      }
    }
    return false;
  },

  @discourseComputed(
    "currentUser",
    "webinar.{id,starts_at,ends_at,approval_type}"
  )
  userCanRegister(user, webinar) {
    if (this.registered || webinar.approval_type === this.NO_REGISTRATION)
      return false;
    return true;
  },

  actions: {
    register() {
      this.set("loading", true);
      ajax(
        `/zoom/webinars/${this.webinar.zoom_id}/register/${this.currentUser.username}`,
        { type: "PUT" }
      )
        .then(response => {
          this.setProperties({
            registrationSuccessful: true,
            loading: false
          });
        })
        .catch(() => {
          this.set("loading", false);
        });
    }
  }
});
