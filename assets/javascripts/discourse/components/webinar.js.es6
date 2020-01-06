import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";

export default Component.extend({
  preview: false,
  details: null,
  webinarId: null,
  loading: false,
  waiting: null,
  registering: false,
  updateDetails: null,
  registered: false,

  AUTOMATIC_APPROVAL: "automatic",
  MANUAL_APPROVAL: "manual",
  NO_REGISTRATION: "no_registration",

  BEFORE_VALUE: "before",
  DURING_VALUE: "during",
  AFTER_VALUE: "after",

  init() {
    this._super(...arguments);
    this.updateDetails = this.updateDetails || (() => {});
    this.fetchDetails();
  },

  didUpdateAttrs() {
    this._super(...arguments);
    this.fetchDetails();
  },

  @discourseComputed("details.webinar.{starts_at,details.ends_at}")
  schedule(details) {
    const start = moment(details.starts_at);
    const end = moment(details.ends_at);
    return `${start.format("LT")} - ${end.format("LT")}, ${start.format(
      "Do MMMM, Y"
    )}`;
  },

  @discourseComputed("currentUser.webinar_registrations")
  registered(userRegistrations) {
    for (let registration of userRegistrations) {
      if (registration.webinar_id === this.details.webinar.id) {
        return true;
      }
    }
    return false;
  },

  @discourseComputed(
    "currentUser",
    "details.webinar.{id,starts_at,ends_at,approval_type}",
    "preview"
  )
  userCanRegister(user, webinar, preview) {
    if (
      preview ||
      this.state === this.AFTER_VALUE ||
      webinar.approval_type === this.NO_REGISTRATION ||
      this.registered
    )
      return false;

    return true;
  },

  @discourseComputed("details.webinar.{starts_at,details.ends_at}")
  state(webinar) {
    let state;
    const now = new Date();
    const start = new Date(webinar.starts_at);
    const end = new Date(webinar.ends_at);

    if (now < start) state = this.BEFORE_VALUE;
    else if (now >= start && now < end) state = this.DURING_VALUE;
    else state = this.AFTER_VALUE;
    return state;
  },

  fetchDetails() {
    if (!this.webinarId) return;

    this.set("loading", true);
    ajax(`/zoom/webinars/${this.webinarId}`)
      .then(results => {
        this.updateDetails(this.details);
        this.setProperties({
          waiting: false,
          loading: false,
          details: results
        });
      })
      .catch(() => {
        this.set("loading", false);
      });
  },

  actions: {
    register() {
      this.set("loading", true);
      ajax(
        `/zoom/webinars/${this.webinarId}/register/${this.currentUser.username}`,
        { type: "PUT" }
      )
        .then(response => {
          this.currentUser.set("webinar_registrations", response.webinars);
          this.set("loading", false);
        })
        .catch(() => {
          this.set("loading", false);
        });
    }
  }
});
