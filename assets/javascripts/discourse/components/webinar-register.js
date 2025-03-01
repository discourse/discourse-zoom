import Component from "@ember/component";
import { action } from "@ember/object";
import { or } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";
import discourseComputed from "discourse/lib/decorators";
import { postRNWebviewMessage } from "discourse/lib/utilities";

const STARTED = "started",
  ENDED = "ended";

export default class WebinarRegister extends Component {
  loading = false;

  @or("isHost", "isPanelist", "isAttendee") registered;

  @discourseComputed("webinar.{status,ends_at}")
  webinarStarted(webinar) {
    const beforeStart = this.siteSettings.zoom_join_x_mins_before_start;

    if (webinar.status === STARTED) {
      if (!beforeStart) {
        return true;
      }

      const newStartTime = moment(webinar.starts_at).subtract(
        beforeStart,
        "minutes"
      );

      if (newStartTime.isBefore(moment())) {
        return true;
      }
    }
    return false;
  }

  @discourseComputed("webinar.{status,ends_at}")
  webinarEnded(webinar) {
    if (
      webinar.status === ENDED ||
      moment(webinar.ends_at).isBefore(moment())
    ) {
      return true;
    }
    return false;
  }

  @discourseComputed
  isAppWebview() {
    return this.capabilities.isAppWebview;
  }

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
  }

  @discourseComputed("currentUser", "webinar.host")
  isHost(user, host) {
    if (host) {
      return user.id === host.id;
    }
    return false;
  }

  @discourseComputed("currentUser", "webinar.panelists")
  isPanelist(user, panelists) {
    for (let panelist of panelists) {
      if (panelist.id === user.id) {
        return true;
      }
    }

    return false;
  }

  @discourseComputed("webinar.starts_at", "isAttendee", "registered")
  canUnregister(starts_at, isAttendee, registered) {
    if (moment(starts_at).isBefore(moment())) {
      return false;
    }

    return isAttendee && registered;
  }

  @discourseComputed("isAttendee", "registered")
  userCanRegister(isAttendee, registered) {
    return !isAttendee && !registered;
  }

  toggleRegistration(registering) {
    const method = registering ? "PUT" : "DELETE";
    this.set("loading", true);
    return ajax(
      `/zoom/webinars/${this.webinar.id}/attendees/${this.currentUser.username}.json`,
      { type: method }
    )
      .then(() => {
        this.store.find("webinar", this.webinar.id).then((webinar) => {
          this.set("webinar", webinar);
        });
        this.set("loading", false);
      })
      .finally(() => this.set("loading", false));
  }

  @discourseComputed("webinar.title")
  downloadName(title) {
    return title + ".ics";
  }

  @discourseComputed("webinar.{starts_at,ends_at}")
  addToGoogleCalendarUrl(webinar) {
    return `http://www.google.com/calendar/event?action=TEMPLATE&text=${encodeURIComponent(
      webinar.title
    )}&dates=${this.formatDateForGoogleApi(
      webinar.starts_at
    )}/${this.formatDateForGoogleApi(
      webinar.ends_at
    )}&details=${encodeURIComponent(
      this.formatDescriptionForGoogleApi(webinar.join_url)
    )}&location=${encodeURIComponent(webinar.join_url)}`;
  }

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
  }

  @discourseComputed("webinar.join_url")
  joinViaZoom(joinUrl) {
    if (joinUrl && this.siteSettings.zoom_use_join_url) {
      return joinUrl;
    } else {
      return false;
    }
  }

  formatDateForGoogleApi(date) {
    return new Date(date).toISOString().replace(/-|:|\.\d\d\d/g, "");
  }

  formatDescriptionForGoogleApi(joinUrl) {
    return `Join from a PC, Mac, iPad, iPhone or Android device:
    Please click this URL to join. <a href="${joinUrl}">${joinUrl}</a>`;
  }

  formatDateForIcs(date) {
    return moment(date).utc().format("YYYYMMDDTHHmmss") + "Z";
  }

  @action
  register() {
    this.toggleRegistration(true);
  }

  @action
  unregister() {
    this.toggleRegistration(false);
  }

  @action
  addEventAppWebview() {
    const event = {
      title: this.webinar.title,
      starts_at: this.webinar.starts_at,
      ends_at: this.webinar.ends_at,
    };
    postRNWebviewMessage("eventRegistration", JSON.stringify(event));
  }

  @action
  joinSDK() {
    const url = this.siteSettings.zoom_enable_sdk_fallback
      ? `/zoom/webinars/${this.webinar.id}/sdk?fallback=1`
      : `/zoom/webinars/${this.webinar.id}/sdk`;

    if (this.registered) {
      window.location.href = url;
    } else {
      this.toggleRegistration(true).then(() => {
        window.location.href = url;
      });
    }
  }
}
