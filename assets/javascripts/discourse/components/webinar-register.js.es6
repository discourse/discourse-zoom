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
    "webinar.panelists",
    "webinar.host",
    "registrationSuccessful"
  )
  registered(user, attendees, panelists, host, registrationSuccessful) {
    if (registrationSuccessful) return true;

    const allRegistered = [host].concat(panelists || []).concat(attendees || [])
    for (let registeredUser of allRegistered) {
      if (registeredUser.id === user.id) {
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
    return (webinar.approval_type !== this.NO_REGISTRATION && !this.registered)
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
