import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { formattedSchedule } from "../lib/webinar-helpers";
import { ajax } from "discourse/lib/ajax";

export default Component.extend({
  preview: false,
  webinar: null,
  webinarId: null,
  loading: false,
  waiting: null,
  registering: false,
  updateDetails: null,
  registered: false,

  init() {
    this._super(...arguments);
    this.updateDetails = this.updateDetails || (() => {});
  },

  didUpdateAttrs() {
    this._super(...arguments);
    this.fetchDetails();
  },

  @discourseComputed("webinar.{starts_at,webinar.ends_at}")
  schedule(webinar) {
    return formattedSchedule(webinar.starts_at, webinar.ends_at)
  },

  fetchDetails() {
    if (!this.webinarId) return;

    this.set("loading", true);
    ajax(`/zoom/webinars/${this.webinarId}/preview`)
      .then(results => {
        this.setProperties({
          waiting: false,
          loading: false,
          webinar: results
        });
        this.updateDetails(this.webinar);
      })
      .catch((e) => {
        this.set("loading", false);
      });
  }
});