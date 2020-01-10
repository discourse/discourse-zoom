import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { formattedSchedule } from "../lib/webinar-helpers";
import { ajax } from "discourse/lib/ajax";

export default Component.extend({
  loading: false,
  webinar: null,
  webinarId: null,
  showTimer: false,

  hostDisplayName: Ember.computed.or(
    "webinar.host.name",
    "webinar.host.username"
  ),

  init() {
    this._super(...arguments);
    this.fetchDetails();
  },

  @discourseComputed("webinar.{starts_at,webinar.ends_at}")
  schedule(webinar) {
    return formattedSchedule(webinar.starts_at, webinar.ends_at);
  },

  fetchDetails() {
    if (!this.webinarId) return;

    this.set("loading", true);
    this.store
      .find("webinar", this.webinarId)
      .then(results => {
        this.setProperties({
          loading: false,
          webinar: results
        });
        this.timerDisplay();
      })
      .catch(e => {
        this.set("loading", false);
      });
  },

  timerDisplay() {
    const starts_at = moment(this.webinar.starts_at);

    this.interval = setInterval(() => {
      const duration = moment.duration(starts_at.diff(moment()));
      this.set("cSecs", duration.seconds());
      this.set("cMins", duration.minutes());
      this.set("cHours", duration.hours());
      this.set("cDays", parseInt(duration.asDays()));

      if (starts_at.isBefore(moment())) {
        this.set("showTimer", false);
        clearInterval(this.interval);
      } else {
        this.set("showTimer", true);
      }
    }, 1000);
  },

  willDestroyElement() {
    clearInterval(this.interval);
  }
});
