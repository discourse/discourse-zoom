import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not } from "@ember/object/computed";
import { makeArray } from "discourse-common/lib/helpers";
import DModal from "discourse/components/d-modal";
import DButton from "discourse/components/d-button";
import DateInput from "discourse/components/date-input";
import eq from "truth-helpers/helpers/eq";
import { Input } from "@ember/component";
import i18n from "discourse-common/helpers/i18n";
import EmailGroupUserChooser from "select-kit/components/email-group-user-chooser";
import { fn } from "@ember/helper";
import ConditionalLoadingSection from "discourse/components/conditional-loading-section";
import WebinarOptionRow from "../webinar-option-row";

const NONZOOM = "nonzoom";
const NO_REGISTRATION_REQUIRED = 2;

export default class WebinarPicker extends Component {
  @service store;

  @tracked webinarId = null;
  @tracked webinarIdInput = null;
  @tracked webinar = null;
  @tracked loading = false;
  @tracked selected = false;
  @tracked addingPastWebinar = false;
  @tracked pastStartDate = moment(new Date(), "YYYY-MM-DD").toDate();
  @tracked pastWebinarTitle = "";
  @tracked allWebinars = null;
  @tracked error = false;

  constructor() {
    super(...arguments);
    this.loadWebinars();
  }

  get model() {
    return this.args.model.topic;
  }

  get webinarError() {
    if (this.webinar.approval_type !== NO_REGISTRATION_REQUIRED) {
      return I18n.t("zoom.no_registration_required");
    }
    if (this.webinar.existing_topic) {
      return I18n.t("zoom.webinar_existing_topic", {
        topic_id: this.webinar.existing_topic.topic_id,
      });
    }
    return false;
  }

  @action
  async fetchWebinarDetails(id) {
    id = this.scrubWebinarId(id.toString());
    this.loading = true;
    this.error = false;

    try {
      const json = await ajax(`/zoom/webinars/${id}/preview`);
      this.webinar = json;
      this.selected = true;
    } catch (error) {
      this.webinar = null;
      this.selected = false;
      this.error = true;
    } finally {
      this.loading = false;
    }
  }

  get pastWebinarDisabled() {
    return !this.pastWebinarTitle || !this.pastStartDate;
  }

  @action
  selectWebinar(id) {
    this.fetchWebinarDetails(id);
  }

  @action
  clear() {
    this.selected = false;
  }

  @action
  async insert() {
    if (this.model.addToTopic) {
      this.addWebinarToTopic();
    } else {
      this.addWebinarToComposer();
    }
    this.args.closeModal();
  }

  @action
  async addPastWebinar() {
    this.model.zoomId = NONZOOM;
    this.model.zoomWebinarTitle = this.pastWebinarTitle;
    this.model.zoomWebinarStartDate = moment(this.pastStartDate).format();
    if (this.model.addToTopic) {
      this.addWebinarToTopic();
    }
    this.args.closeModal();
  }

  @action
  showPastWebinarForm() {
    this.addingPastWebinar = true;
    this.selected = false;
  }

  @action
  onChangeDate(date) {
    if (date) {
      this.pastStartDate = date;
    }
  }

  scrubWebinarId(webinarId) {
    return webinarId.replace(/-|\s/g, "");
  }

  async loadWebinars() {
    if (!this.webinar) {
      if (this.model && this.model.webinar?.zoom_id) {
        this.webinarId = this.model.webinar.zoom_id;
        this.webinarIdInput = this.model.webinar.zoom_id;
      }

      if (!this.selected) {
        const results = await ajax("/zoom/webinars");
        if (results && results.webinars) {
          this.allWebinars = results.webinars;
        }
      }
    }
  }

  async addWebinarToTopic() {
    const webinarId = this.webinar?.id || NONZOOM;
    let data = {};
    if (this.pastWebinarTitle && this.pastStartDate) {
      data = {
        zoom_title: this.pastWebinarTitle,
        zoom_start_date: moment(this.pastStartDate).format(),
      };
    }

    try {
      const results = await ajax(
        `/zoom/t/${this.model.id}/webinars/${webinarId}`,
        {
          type: "PUT",
          data,
        }
      );
      const webinar = await this.store.find("webinar", results.id);
      this.model.webinar = webinar;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
      // this.topicController.editingTopic = false;
      this.model.postStream.posts[0].rebake();
      document.querySelector("body").classList.add("has-webinar");
    }
  }

  async addWebinarToComposer() {
    this.model.zoomId = this.webinar.id;
    this.model.zoomWebinarTitle = this.webinar.title;
  }

  <template>
    <DModal
      id="edit-webinar-modal"
      @title={{i18n "zoom.webinar_picker.title"}}
      @closeModal={{@closeModal}}
    >
      <:body>
        <ConditionalLoadingSection @condition={{this.loading}}>
          {{#if this.selected}}
            {{#if this.webinar}}
              {{#if this.webinarError}}
                <div class="alert alert-error">
                  {{this.webinarError}}
                </div>
              {{/if}}

              <div class="webinar-content">
                <div class="webinar-title bold">
                  {{this.webinar.title}}
                </div>

                <div class="occurrence-start-time">
                  {{this.schedule}}
                </div>

                <h3 class="host">
                  {{i18n "zoom.hosted_by"}}
                </h3>

                <div class="host-container">
                  <img
                    class="avatar"
                    src={{this.webinar.host.avatar_url}}
                    width="80"
                    height="80"
                    title={{this.details.host.name}}
                  />

                  <div class="host-description">
                    <div class="host-name">
                      {{this.webinar.host.name}}
                    </div>
                    <div class="group-name">
                      {{this.webinar.host.title}}
                    </div>
                  </div>
                </div>

                <h3>
                  {{i18n "zoom.panelists"}}
                </h3>

                <div class="panelists">
                  {{#if this.webinar.panelists}}
                    <div class="panelist-avatars">
                      {{#each this.webinar.panelists as |panelist|}}
                        <img
                          class="avatar"
                          src={{panelist.avatar_url}}
                          width="25"
                          height="25"
                          alt={{panelist.name}}
                          title={{panelist.name}}
                        />
                      {{/each}}
                    </div>
                  {{else}}
                    <div class="no-panelists">
                      {{i18n "zoom.no_panelists_preview"}}
                    </div>
                  {{/if}}
                </div>
              </div>
            {{/if}}
          {{else}}
            {{#if this.error}}
              <div class="alert alert-error">
                {{i18n "zoom.error"}}
              </div>
            {{/if}}

            {{#if this.addingPastWebinar}}
              <div class="webinar-past-input webinar-past-start-date">
                <label>
                  {{i18n "zoom.past_date"}}
                </label>
                <DateInput
                  @date={{this.pastStartDate}}
                  @onChange={{this.onChangeDate}}
                />
              </div>

              <div class="webinar-past-input webinar-past-title">
                <label>
                  {{i18n "zoom.past_label"}}
                </label>
                <Input
                  @type="text"
                  @value={{this.pastWebinarTitle}}
                  class="webinar-past-title"
                />
              </div>

              <DButton
                @action={{this.addPastWebinar}}
                @icon="plus"
                @label="zoom.webinar_picker.create"
                @disabled={{this.pastWebinarDisabled}}
              />
            {{else}}
              <div class="inline-form webinar-picker-input">
                <Input
                  @type="text"
                  @value={{this.webinarIdInput}}
                  class="webinar-builder-id"
                />
                <DButton
                  @action={{fn this.selectWebinar this.webinarIdInput}}
                  @icon="plus"
                />
              </div>

              <div class="webinar-picker-add-past">
                <DButton
                  @action={{this.showPastWebinarForm}}
                  @label="zoom.add_past_webinar"
                  class="btn-flat past-webinar"
                />
              </div>

              <div class="webinar-picker-webinars">
                {{#each this.allWebinars as |webinar|}}
                  <WebinarOptionRow
                    @model={{webinar}}
                    @onSelect={{fn this.selectWebinar webinar.id}}
                  />
                {{/each}}
              </div>
            {{/if}}
          {{/if}}
        </ConditionalLoadingSection>
      </:body>
      <:footer>
        {{#if this.selected}}
          {{#if (not this.webinarError)}}
            <DButton
              @action={{this.insert}}
              class="btn-primary"
              @label="zoom.webinar_picker.create"
            />
          {{/if}}
          <DButton
            @action={{this.clear}}
            @label="zoom.webinar_picker.clear"
            class="btn-flat"
          />
        {{/if}}
      </:footer>
    </DModal>
  </template>
}
