import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { or, equal } from "@ember/object/computed";

const STARTED = "started",
  ENDED = "ended";

export default Component.extend({
  loading: false,
  registered: or("isHost", "isPanelist", "isAttendee"),
  webinarStarted: equal("webinar.status", STARTED),
  webinarEnded: equal("webinar.status", ENDED),

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

  @discourseComputed("webinar.{starts_at,ends_at}")
  addToGoogleCalendarUrl(webinar) {
    return `http://www.google.com/calendar/event?action=TEMPLATE&text=${encodeURIComponent(
      webinar.title
    )}&dates=${this.formatDateForGoogleApi(
      webinar.starts_at
    )}/${this.formatDateForGoogleApi(webinar.ends_at)}`;
  },

  formatDateForGoogleApi(date) {
    return new Date(date).toISOString().replace(/-|:|\.\d\d\d/g, "");
  },

  formatDateForIcs(date) {
    date = new Date(date)
  var pre =
    date.getFullYear().toString() +
    ((date.getMonth() + 1)<10? "0" + (date.getMonth() + 1).toString():(date.getMonth() + 1).toString()) +
    ((date.getDate() + 1)<10? "0" + date.getDate().toString():date.getDate().toString());

    var post = (date.getHours()%12).toString() + date.getMinutes().toString() + "00";
    console.log(pre + "T" + post)
    return pre + "T" + post + "Z"
  },

  @discourseComputed("webinar.{starts_at,ends_at}")
  downloadIcsUrl(webinar) {
    return `data:text/calendar;charset=utf-8,
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
DTSTAMP: ${this.formatDateForIcs((new Date).toString())}
DTSTART:${this.formatDateForIcs(webinar.starts_at)}
DTEND:${this.formatDateForIcs(webinar.ends_at)}
SUMMARY:${webinar.title}
END:VEVENT
END:VCALENDAR`
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
          window.location.href = url;
        });
      }
    }
  }
});
