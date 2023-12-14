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
import { fn, hash } from "@ember/helper";

export default class EditWebinar extends Component {
  @service store;

  @tracked newPanelist;
  @tracked loading = false;
  @tracked newVideoUrl = this.args.model.webinar.video_url;
  @tracked hostUsername = this.args.model.webinar.host?.username;
  @tracked pastStartDate = this.args.model.webinar.starts_at;
  @tracked title = this.args.model.webinar.title;

  get canSaveVideoUrl() {
    const saved = this.args.model.webinar.video_url;
    if (saved === this.newVideoUrl || this.loading) {
      return true;
    }
    return saved === (this.newVideoUrl === null ? "" : this.newVideoUrl);
  }

  get excludedUsernames() {
    const panelists = this.args.model.webinar.panelists;
    const host = makeArray(this.args.model.webinar.host);
    return panelists.concat(host).map((p) => p.username);
  }

  get addingDisabled() {
    return this.loading || !this.newPanelist;
  }

  get updateDetailsDisabled() {
    return (
      this.loading ||
      (this.args.model.webinar.title === this.title &&
        this.args.model.webinar.starts_at === this.pastStartDate)
    );
  }

  @action
  async saveVideoUrl() {
    this.loading = true;
    try {
      const results = await ajax(
        `/zoom/webinars/${this.args.model.webinar.id}/video_url.json`,
        {
          data: { video_url: this.newVideoUrl },
          type: "PUT",
        }
      );
      this.newVideoUrl = results.video_url;
      this.args.model.setVideoUrl(results.video_url);
    } finally {
      this.loading = false;
    }
  }

  @action
  resetVideoUrl() {
    this.newVideoUrl = this.args.model.webinar.video_url;
  }

  @action
  async removePanelist(panelist) {
    this.loading = true;
    try {
      await ajax(
        `/zoom/webinars/${this.args.model.webinar.id}/panelists/${panelist.username}.json`,
        {
          type: "DELETE",
        }
      );

      const webinar = await this.store.find(
        "webinar",
        this.args.model.webinar.id
      );
      this.args.model.webinar = webinar;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  async addPanelist() {
    this.loading = true;

    try {
      await ajax(
        `/zoom/webinars/${this.args.model.webinar.id}/panelists/${this.newPanelist}.json`,
        {
          type: "PUT",
        }
      );
      this.newPanelist = null;
      const webinar = await this.store.find(
        "webinar",
        this.args.model.webinar.id
      );
      this.args.model.setWebinar(webinar);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  onChangeDate(date) {
    if (date) {
      this.pastStartDate = date;
      this.args.model.setStartsAt(date);
    }
  }

  @action
  async onChangeHost(selected) {
    this.hostUsername = selected.firstObject;
    this.loading = true;
    let hostUsername = this.hostUsername;
    let postType = "PUT";

    if (!this.hostUsername) {
      hostUsername = this.args.model.webinar.host.username;
      postType = "DELETE";
    }

    try {
      await ajax(
        `/zoom/webinars/${this.args.model.webinar.id}/nonzoom_host/${hostUsername}.json`,
        {
          type: postType,
        }
      );

      const webinar = await this.store.find(
        "webinar",
        this.args.model.webinar.id
      );
      this.args.model.setWebinar(webinar);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  async updateDetails() {
    this.loading = true;

    try {
      await ajax(
        `/zoom/webinars/${this.args.model.webinar.id}/nonzoom_details.json`,
        {
          type: "PUT",
          data: {
            title: this.title,
            past_start_date: moment(this.pastStartDate).format(),
          },
        }
      );

      this.args.model.setTitle(this.title);
      this.args.model.setStartsAt(this.pastStartDate);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  updateNewPanelist(selected) {
    this.newPanelist = selected.firstObject;
  }

  <template>
    <DModal
      id="edit-webinar-modal"
      @title={{i18n "zoom.edit_webinar"}}
      @closeModal={{@closeModal}}
    >
      <:body>
        {{#if (eq @model.webinar.zoom_id "nonzoom")}}
          <div class="webinar-nonzoom-details">
            <h3>{{i18n "zoom.nonzoom_details"}}</h3>
            <h4>{{i18n "zoom.host"}}</h4>

            <div class="update-host-input">
              <EmailGroupUserChooser
                @value={{this.hostUsername}}
                @onChange={{this.onChangeHost}}
                @options={{hash
                  filterPlaceholder="zoom.select_host"
                  maximum=1
                  allowEmails=true
                }}
              />
            </div>

            <h4>{{i18n "zoom.title_date"}}</h4>
            <span class="update-host-details">
              <Input @value={{this.title}} id="webinar-title" />
              <DateInput
                @date={{this.pastStartDate}}
                @onChange={{this.onChangeDate}}
              />

              <DButton
                @action={{this.updateDetails}}
                class="update-details-btn btn-primary"
                @icon="check"
                @disabled={{this.updateDetailsDisabled}}
              />
            </span>
          </div>
        {{/if}}

        <div class="webinar-panelists">
          <h3>{{i18n "zoom.panelists"}}</h3>
          {{#if this.args.model.webinar.panelists}}
            {{#each this.args.model.webinar.panelists as |panelist|}}
              <div class="webinar-panelist">
                {{panelist.username}}
                <DButton
                  @action={{fn this.removePanelist panelist}}
                  class="remove-panelist-btn btn-danger"
                  @icon="times"
                  @disabled={{this.loading}}
                />
              </div>
            {{/each}}
          {{else}}
            {{i18n "zoom.no_panelists"}}
          {{/if}}
        </div>

        <div class="webinar-add-panelist">
          <h3>{{i18n "zoom.add_panelist"}}</h3>

          <span class="new-panelist-input">
            <EmailGroupUserChooser
              @value={{this.newPanelist}}
              @onChange={{this.updateNewPanelist}}
              @options={{hash
                filterPlaceholder="zoom.select_panelist"
                maximum=1
                excludedUsernames=this.excludedUsernames
              }}
            />
          </span>
          <DButton
            @action={{this.addPanelist}}
            class="new-panelist-btn btn-primary"
            @icon="plus"
            @disabled={{this.addingDisabled}}
          />
        </div>

        <div class="webinar-add-video">
          <h3>{{i18n "zoom.webinar_recording"}}</h3>
          <p>{{i18n "zoom.webinar_recording_description"}}</p>
          <Input
            @value={{this.newVideoUrl}}
            id="webinar-video-url"
            name="video url"
            autocomplete="discourse"
          />
          <DButton
            @action={{this.saveVideoUrl}}
            class="new-panelist-btn btn-primary"
            @icon="check"
            @disabled={{this.canSaveVideoUrl}}
          />
          <DButton
            @action={{this.resetVideoUrl}}
            class="new-panelist-btn btn-danger"
            @icon="times"
            @disabled={{this.canSaveVideoUrl}}
          />
        </div>
      </:body>
    </DModal>
  </template>
}
