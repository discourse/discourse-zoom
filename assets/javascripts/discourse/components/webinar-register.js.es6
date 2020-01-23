import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { or, equal } from "@ember/object/computed";
import { isAppWebview, postRNWebviewMessage } from "discourse/lib/utilities";

const STARTED = "started",
  ENDED = "ended";

export default Component.extend({
  loading: false,
  registered: or("isHost", "isPanelist", "isAttendee"),
  webinarStarted: equal("webinar.status", STARTED),
  webinarEnded: equal("webinar.status", ENDED),

  init() {
    this._super(...arguments);
  },

  @discourseComputed
  isAppWebview() {
    return isAppWebview();
  },
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
    if (host) {
      return user.id === host.id;
    }
    return false;
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

  @discourseComputed("webinar.starts_at", "webinar.attendees")
  canUnregister(starts_at, attendees) {
    if (moment(starts_at).isBefore(moment())) {
      return false;
    }
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
      `/zoom/webinars/${this.webinar.id}/attendees/${this.currentUser.username}.json`,
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

  @discourseComputed("webinar.title")
  downloadName(title) {
    return title + ".ics";
  },

  @discourseComputed("webinar.{starts_at,ends_at}")
  addToGoogleCalendarUrl(webinar) {
    return `http://www.google.com/calendar/event?action=TEMPLATE&text=${encodeURIComponent(
      webinar.title
    )}&dates=${this.formatDateForGoogleApi(
      webinar.starts_at
    )}/${this.formatDateForGoogleApi(webinar.ends_at)}`;
  },

  @discourseComputed("webinar.{starts_at,ends_at}")
  downloadIcsUrl(webinar) {
    const now = this.formatDateForIcs(new Date());

    return (
      `data:text/calendar;charset=utf-8,` +
      encodeURIComponent(
        `BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//hacksw/handcal//NONSGML v1.0//EN\nBEGIN:VEVENT\nUID:${now}-${
          webinar.title
        }\nDTSTAMP:${now}\nDTSTART:${this.formatDateForIcs(
          webinar.starts_at
        )}\nDTEND:${this.formatDateForIcs(webinar.ends_at)}\nSUMMARY:${
          webinar.title
        }\nEND:VEVENT\nEND:VCALENDAR`
      )
    );
  },

  formatDateForGoogleApi(date) {
    return new Date(date).toISOString().replace(/-|:|\.\d\d\d/g, "");
  },

  formatDateForIcs(date) {
    return (
      moment(date)
        .utc()
        .format("YYYYMMDDTHHmmss") + "Z"
    );
  },

  actions: {
    register() {
      this.toggleRegistration(true);
    },

    unregister() {
      this.toggleRegistration(false);
    },

    addEventAppWebview() {
      const event = {
        title: this.webinar.title,
        starts_at: this.webinar.starts_at,
        ends_at: this.webinar.ends_at
      };
      postRNWebviewMessage("eventRegistration", JSON.stringify(event));
    },

    joinSDK() {
      const url = `/zoom/webinars/${this.webinar.id}/sdk`;

      if (this.registered) {
        window.location.href = url;
      } else {
        this.toggleRegistration(true).then(response => {
          window.location.href = url;
        });
      }
    }
  }
});
