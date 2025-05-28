import Component from "@ember/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { alias, or } from "@ember/object/computed";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import $ from "jquery";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import DButton from "discourse/components/d-button";
import avatar from "discourse/helpers/avatar";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import discourseComputed from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";
import EditWebinar from "../components/modal/edit-webinar";
import { formattedSchedule } from "../lib/webinar-helpers";
import WebinarRegister from "./webinar-register";

const PENDING = "pending",
  ENDED = "ended",
  STARTED = "started";

export default class Webinar extends Component {
  @service modal;

  loading = false;
  topic = null;
  webinar = null;
  webinarId = null;
  showTimer = false;

  @alias("topic.details.can_edit") canEdit;

  showingRecording = false;

  @or("webinar.host.name", "webinar.host.username") hostDisplayName;

  init() {
    super.init(...arguments);
    this.fetchDetails();
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

  @discourseComputed("webinar.status")
  webinarStarted(status) {
    return status === STARTED;
  }

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
  }

  willDestroyElement() {
    super.willDestroyElement(...arguments);
    if (this.webinar) {
      this.messageBus.unsubscribe(this.messageBusEndpoint);
    }
    clearInterval(this.interval);
  }

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
  }

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
  }

  @discourseComputed("webinar")
  messageBusEndpoint(webinar) {
    return `/zoom/webinars/${webinar.id}`;
  }

  @discourseComputed
  displayAttendees() {
    return this.siteSettings.zoom_display_attendees;
  }

  @discourseComputed("webinar.{starts_at,ends_at}")
  schedule(webinar) {
    if (webinar.ends_at === null) {
      return moment(webinar.starts_at).format("Do MMMM, Y");
    }
    return formattedSchedule(webinar.starts_at, webinar.ends_at);
  }

  @action
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
  }

  @action
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
  }

  <template>
    {{#if this.webinar}}
      <div class="webinar-content">
        <div class="webinar-header">
          <div class="webinar-title-section">
            <div class="webinar-title bold">
              {{this.webinar.title}}
              {{#if this.canEdit}}
                <a
                  href
                  {{on "click" this.editPanelists}}
                  class="edit-panelists"
                  title={{i18n "edit"}}
                >
                  {{icon "pencil"}}
                </a>
              {{/if}}
            </div>
            <div class="occurrence-start-time">{{this.schedule}}</div>
          </div>

          {{#if this.setupTimer}}
            {{#if this.showTimer}}
              <div class="countdown-wrapper">
                <div class="countdown-label">{{i18n
                    "zoom.countdown_label"
                  }}</div>
                <div class="countdown">
                  <div class="pill">
                    {{this.cDays}}
                    <div>{{i18n "zoom.days"}}</div>
                  </div>
                  <div class="pill">
                    {{this.cHours}}
                    <div>{{i18n "zoom.hours"}}</div>
                  </div>
                  <div class="pill">
                    {{this.cMins}}
                    <div>{{i18n "zoom.mins"}}</div>
                  </div>
                  <div class="pill">
                    {{this.cSecs}}
                    <div>{{i18n "zoom.secs"}}</div>
                  </div>
                </div>
              </div>
            {{/if}}
          {{/if}}
        </div>

        {{#if this.webinar.host}}
          <div class="host">{{i18n "zoom.hosted_by"}}</div>
          <div class="host-container">
            <a
              href="/u/{{this.webinar.host.username}}"
              data-user-card={{this.webinar.host.username}}
            >
              {{avatar this.webinar.host imageSize="large"}}
            </a>
            <div class="host-description">
              <div class="host-name">{{this.hostDisplayName}}</div>
              <div class="group-name">{{this.webinar.host.title}}</div>
            </div>
          </div>
        {{/if}}

        {{#if this.webinar.panelists}}
          <div class="panelists">
            {{i18n "zoom.panelists"}}
            <div class="panelist-avatars">
              {{#each this.webinar.panelists as |panelist|}}
                <a
                  href="/u/{{panelist.username}}"
                  data-user-card={{panelist.username}}
                >
                  {{avatar panelist imageSize="small"}}
                </a>
              {{/each}}
            </div>
          </div>
        {{/if}}

        {{#if this.currentUser}}
          <WebinarRegister
            @webinar={{this.webinar}}
            @showCalendarButtons={{true}}
          />
        {{/if}}

        {{#if this.webinarEnded}}
          <div class="event-ended">
            {{#if this.webinar.video_url}}
              <div class="video-recording">
                {{#if this.showingRecording}}
                  <video
                    controlslist="nodownload"
                    width="100%"
                    height="100%"
                    src={{this.webinar.video_url}}
                    controls
                  ></video>
                {{else}}
                  {{#if this.webinar.video_url}}
                    <DButton
                      @action={{this.showRecording}}
                      class="btn-primary"
                      @label="zoom.show_recording"
                      @icon="play"
                    />
                  {{/if}}
                {{/if}}
              </div>
            {{else}}
              {{i18n "zoom.webinar_ended"}}
            {{/if}}
          </div>
        {{else}}
          {{#if this.displayAttendees}}
            {{#if this.webinar.attendees}}
              <div class="attendees">
                {{i18n "zoom.attendees"}}

                <div class="attendee-avatars">
                  {{#each this.webinar.attendees as |attendee|}}
                    {{avatar attendee imageSize="small"}}
                  {{/each}}
                </div>
              </div>
            {{/if}}
          {{/if}}

          {{#unless this.webinarStarted}}
            <div class="webinar-footnote">
              {{#if this.currentUser}}
                {{i18n "zoom.webinar_footnote"}}
              {{else}}
                {{i18n "zoom.webinar_logged_in_users_only"}}
              {{/if}}
            </div>
          {{/unless}}
        {{/if}}
      </div>
    {{else}}
      <ConditionalLoadingSpinner @condition={{this.loading}} />
    {{/if}}
  </template>
}
