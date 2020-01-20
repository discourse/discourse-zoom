import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { formattedSchedule } from "../lib/webinar-helpers";
import showModal from "discourse/lib/show-modal";
import { alias, or, equal } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";

const NOT_STARTED = "not_started",
  ENDED = "ended";

export default Component.extend({
  loading: false,
  topic: null,
  webinar: null,
  webinarId: null,
  showTimer: false,
  canEdit: alias("topic.details.can_edit"),
  webinarEnded: equal("webinar.status", ENDED),
  showingRecording: false,

  hostDisplayName: Ember.computed.or(
    "webinar.host.name",
    "webinar.host.username"
  ),
  hostDisplayName: or("webinar.host.name", "webinar.host.username"),

  init() {
    this._super(...arguments);
    this.fetchDetails();
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
        this.messageBus.subscribe(this.messageBusEndpoint, data => {
          this.webinar.set("status", data.status);
        });
      })
      .catch(e => {
        this.set("loading", false);
      });
  },

  willDestroyElement() {
    this._super(...arguments);
    if (this.webinar) {
      this.messageBus.unsubscribe(this.messageBusEndpoint);
    }
    clearInterval(this.interval);
  },

  @discourseComputed(
    "webinar",
    "webinar.starts_at",
    "webinar.duration",
    "webinar.status"
  )
  setupTimer(webinar, starts_at, duration, status) {
    if (status !== NOT_STARTED) return false;

    const startsAtMoment = moment(starts_at);
    this.interval = setInterval(
      interval => this.updateTimer(startsAtMoment, interval),
      1000
    );
    this.updateTimer(startsAtMoment);
    return true;
  },

  updateTimer(starts_at, interval) {
    const duration = moment.duration(starts_at.diff(moment()));
    this.set("cSecs", duration.seconds());
    this.set("cMins", duration.minutes());
    this.set("cHours", duration.hours());
    this.set("cDays", parseInt(duration.asDays()));

    if (starts_at.isBefore(moment())) {
      this.set("showTimer", false);
      if (interval) clearInterval(interval);
    } else {
      this.set("showTimer", true);
    }
  },

  @discourseComputed("webinar")
  messageBusEndpoint(webinar) {
    return `/zoom/webinars/${webinar.id}`;
  },

  @discourseComputed("webinar.{starts_at,ends_at}")
  schedule(webinar) {
    return formattedSchedule(webinar.starts_at, webinar.ends_at);
  },

  actions: {
    editPanelists() {
      showModal("edit-webinar", {
        model: this.webinar,
        title: "zoom.edit_webinar"
      });
    },

    showRecording() {
      this.set("showingRecording", true);
    }
  }
});
