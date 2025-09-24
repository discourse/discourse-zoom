import Component from "@ember/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { or } from "@ember/object/computed";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import discourseComputed from "discourse/lib/decorators";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";

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
  unregister(event) {
    event.preventDefault();
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

  <template>
    {{#unless this.webinarEnded}}
      {{#if this.webinarStarted}}
        {{#if this.joinViaZoom}}
          <a href={{this.joinViaZoom}} class="webinar-join-sdk btn btn-primary">
            {{icon "video"}}
            {{i18n "zoom.join_sdk"}}
          </a>
        {{else}}
          <DButton
            @action={{this.joinSDK}}
            class="webinar-join-sdk btn-primary"
            @label="zoom.join_sdk"
            @icon="video"
          />
        {{/if}}
      {{else}}
        {{#if this.registered}}
          <div class="webinar-registered">
            {{#if this.isAttendee}}
              <span class="registered">
                {{icon "far-circle-check"}}
                {{i18n "zoom.registered"}}
              </span>

              {{#if this.canUnregister}}
                <a
                  href
                  {{on "click" this.unregister}}
                  class="btn-flat"
                  title={{i18n "zoom.cancel_registration"}}
                >
                  {{icon "xmark"}}
                </a>
              {{/if}}
            {{/if}}

            {{#if this.showCalendarButtons}}
              <div class="zoom-add-to-calendar-container">
                <a
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn"
                  href={{this.addToGoogleCalendarUrl}}
                >
                  {{i18n "zoom.add_to_google_calendar"}}
                </a>

                {{#if this.isAppWebview}}
                  <DButton
                    @action={{this.addEventAppWebview}}
                    @label="zoom.add_to_calendar"
                    class="btn-default"
                  />
                {{else}}
                  <a
                    target="_blank"
                    rel="noopener noreferrer"
                    class="btn btn-default"
                    href={{this.downloadIcsUrl}}
                    download={{this.downloadName}}
                  >
                    {{i18n "zoom.add_to_outlook"}}
                  </a>
                {{/if}}
              </div>
            {{/if}}
          </div>
        {{else}}
          {{#if this.userCanRegister}}
            <DButton
              @action={{this.register}}
              class="webinar-register-button btn-primary"
              @label="zoom.register"
              @icon="far-calendar-days"
              @disabled={{this.loading}}
            />
          {{/if}}
        {{/if}}
      {{/if}}
    {{/unless}}
  </template>
}
