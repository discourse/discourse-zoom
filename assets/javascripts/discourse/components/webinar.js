import Component from "@ember/component";
import { alias, or } from "@ember/object/computed";
import { next } from "@ember/runloop";
import { inject as service } from "@ember/service";
import $ from "jquery";
import { ajax } from "discourse/lib/ajax";
import discourseComputed from "discourse-common/utils/decorators";
import EditWebinar from "../components/modal/edit-webinar";
import { formattedSchedule } from "../lib/webinar-helpers";

const PENDING = "pending",
  ENDED = "ended",
  STARTED = "started";

export default Component.extend({
  modal: service(),

  loading: false,
  topic: null,
  webinar: null,
  webinarId: null,
  showTimer: false,
  canEdit: alias("topic.details.can_edit"),
  showingRecording: false,

  hostDisplayName: or("webinar.host.name", "webinar.host.username"),

  init() {
    this._super(...arguments);
    this.fetchDetails();
  },

  @discourseComputed("webinar.{status,ends_at}")
  webinarEnded(webinar) {
    if (
      webinar.status === ENDED ||
      moment(webinar.ends_at).isBefore(moment())
    ) {
      return true;
    }
    return false;
  },

  @discourseComputed("webinar.status")
  webinarStarted(status) {
    return status === STARTED;
  },

  fetchDetails() {
    if (!this.webinarId) {
      return;
    }

    this.set("loading", true);
    this.store
      .find("webinar", this.webinarId)
      .then((results) => {
        this.setProperties({
          loading: false,
          webinar: results,
        });
        this.messageBus.subscribe(this.messageBusEndpoint, (data) => {
          this.webinar.set("status", data.status);
        });
        this.appEvents.trigger("discourse-zoom:webinar-loaded");
      })
      .catch(() => {
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
    if (status !== PENDING) {
      return false;
    }

    const startsAtMoment = moment(starts_at);
    this.interval = setInterval(
      (interval) => this.updateTimer(startsAtMoment, interval),
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
    this.set("cDays", parseInt(duration.asDays(), 10));

    if (starts_at.isBefore(moment())) {
      this.set("showTimer", false);
      if (interval) {
        clearInterval(interval);
      }
    } else {
      this.set("showTimer", true);
    }
  },

  @discourseComputed("webinar")
  messageBusEndpoint(webinar) {
    return `/zoom/webinars/${webinar.id}`;
  },

  @discourseComputed
  displayAttendees() {
    return this.siteSettings.zoom_display_attendees;
  },

  @discourseComputed("webinar.{starts_at,ends_at}")
  schedule(webinar) {
    if (webinar.ends_at === null) {
      return moment(webinar.starts_at).format("Do MMMM, Y");
    }
    return formattedSchedule(webinar.starts_at, webinar.ends_at);
  },

  actions: {
    editPanelists() {
      this.modal.show(EditWebinar, {
        model: {
          webinar: this.webinar,
          setWebinar: (value) => this.set("webinar", value),
          setTitle: (value) => this.webinar.set("title", value),
          setStartsAt: (value) => this.webinar.set("starts_at", value),
          setVideoUrl: (value) => this.webinar.set("video_url", value),
        },
      });
    },

    showRecording() {
      this.set("showingRecording", true);
      next(() => {
        const $videoEl = $(".video-recording");

        window.scrollTo({
          top: $videoEl.offset().top - 60,
          behavior: "smooth",
        });
        ajax(
          `/zoom/webinars/${this.webinar.id}/attendees/${this.currentUser.username}/watch.json`,
          { type: "PUT" }
        );
      });
    },
  },
});
