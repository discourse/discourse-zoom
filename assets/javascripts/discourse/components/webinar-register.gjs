/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { on } from "@ember/modifier";
import { action, computed } from "@ember/object";
import { or } from "@ember/object/computed";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";

const STARTED = "started",
  ENDED = "ended";

export default class WebinarRegister extends Component {
  loading = false;

  @or("isHost", "isPanelist", "isAttendee") registered;

  @computed("webinar.{status,ends_at}")
  get webinarStarted() {
    const beforeStart = this.siteSettings.zoom_join_x_mins_before_start;

    if (this.webinar?.status === STARTED) {
      if (!beforeStart) {
        return true;
      }

      const newStartTime = moment(this.webinar?.starts_at)?.subtract(
        beforeStart,
        "minutes"
      );

      if (newStartTime.isBefore(moment())) {
        return true;
      }
    }
    return false;
  }

  @computed("webinar.{status,ends_at}")
  get webinarEnded() {
    if (
      this.webinar?.status === ENDED ||
      moment(this.webinar?.ends_at)?.isBefore(moment())
    ) {
      return true;
    }
    return false;
  }

  @computed
  get isAppWebview() {
    return this.capabilities.isAppWebview;
  }

  @computed("currentUser", "webinar.attendees")
  get isAttendee() {
    if (this.webinar?.attendees) {
      for (let attendee of this.webinar.attendees) {
        if (attendee.id === this.currentUser.id) {
          return true;
        }
      }
    }
    return false;
  }

  @computed("currentUser", "webinar.host")
  get isHost() {
    if (this.webinar?.host) {
      return this.currentUser.id === this.webinar?.host?.id;
    }
    return false;
  }

  @computed("currentUser", "webinar.panelists")
  get isPanelist() {
    for (let panelist of this.webinar.panelists) {
      if (panelist.id === this.currentUser.id) {
        return true;
      }
    }

    return false;
  }

  @computed("webinar.starts_at", "isAttendee", "registered")
  get canUnregister() {
    if (moment(this.webinar?.starts_at).isBefore(moment())) {
      return false;
    }

    return this.isAttendee && this.registered;
  }

  @computed("isAttendee", "registered")
  get userCanRegister() {
    return !this.isAttendee && !this.registered;
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

  @computed("webinar.title")
  get downloadName() {
    return this.webinar?.title + ".ics";
  }

  @computed("webinar.{starts_at,ends_at}")
  get addToGoogleCalendarUrl() {
    return `http://www.google.com/calendar/event?action=TEMPLATE&text=${encodeURIComponent(
      this.webinar?.title
    )}&dates=${this.formatDateForGoogleApi(
      this.webinar?.starts_at
    )}/${this.formatDateForGoogleApi(
      this.webinar?.ends_at
    )}&details=${encodeURIComponent(
      this.formatDescriptionForGoogleApi(this.webinar?.join_url)
    )}&location=${encodeURIComponent(this.webinar?.join_url)}`;
  }

  @computed("webinar.{starts_at,ends_at}")
  get downloadIcsUrl() {
    const now = this.formatDateForIcs(new Date());

    return (
      `data:text/calendar;charset=utf-8,` +
      encodeURIComponent(
        `BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//hacksw/handcal//NONSGML v1.0//EN\nBEGIN:VEVENT\nUID:${now}-${
          this.webinar?.title
        }\nDTSTAMP:${now}\nDTSTART:${this.formatDateForIcs(
          this.webinar?.starts_at
        )}\nDTEND:${this.formatDateForIcs(this.webinar?.ends_at)}\nSUMMARY:${
          this.webinar?.title
        }\nEND:VEVENT\nEND:VCALENDAR`
      )
    );
  }

  @computed("webinar.join_url")
  get joinViaZoom() {
    if (this.webinar?.join_url && this.siteSettings.zoom_use_join_url) {
      return this.webinar?.join_url;
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
