import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { formattedSchedule } from "../lib/webinar-helpers";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed from "discourse-common/utils/decorators";

export default Controller.extend(ModalFunctionality, {
  webinarId: null,
  webinarIdInput: null,
  webinar: null,
  model: null,
  loading: false,
  selected: false,
  allWebinars: null,
  error: false,
  NO_REGISTRATION_REQUIRED: 2,

  onShow() {
    if (!this.webinar) {
      if (this.model && this.model.get("webinar.zoom_id")) {
        this.set("webinarId", this.model.get("webinar.zoom_id"));
        this.set("webinarIdInput", this.model.get("webinar.zoom_id"));
      }

      if (!this.selected) {
        ajax("/zoom/webinars").then(results => {
          if (results && results.webinars) {
            this.set("allWebinars", results.webinars);
          }
        });
      }
    }
  },

  onClose() {
    this.setProperties({
      allWebinars: null,
      selected: false,
      webinarIdInput: null,
      webinar: null,
      error: false
    });
  },

  scrubWebinarId(webinarId) {
    return webinarId.replace(/-|\s/g, "");
  },

  addWebinarToTopic() {
    ajax(`/zoom/t/${this.model.id}/webinars/${this.webinar.id}`, {
      data: { webinar: this.webinar },
      type: "PUT"
    })
      .then(results => {
        this.store.find("webinar", results.id).then(webinar => {
          this.model.set("webinar", webinar);
        });
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.set("loading", false);
        const topicController = Discourse.__container__.lookup(
          "controller:topic"
        );
        topicController.set("editingTopic", false);
      });
  },

  addWebinarToComposer() {
    this.model.setProperties({
      zoomWebinarId: this.webinar.id,
      zoomWebinarHost: this.webinar.host,
      zoomWebinarPanelists: this.webinar.panelists,
      zoomWebinarAttributes: {
        title: this.webinar.title,
        duration: this.webinar.duration,
        starts_at: this.webinar.starts_at,
        ends_at: this.webinar.ends_at,
        zoom_host_id: this.webinar.zoom_host_id,
        password: this.webinar.password,
        host_video: this.webinar.host_video,
        panelists_video: this.webinar.panelists_video,
        approval_type: this.webinar.approval_type,
        enforce_login: this.webinar.enforce_login,
        registrants_restrict_number: this.webinar.registrants_restrict_number,
        meeting_authentication: this.webinar.meeting_authentication,
        on_demand: this.webinar.on_demand,
        join_url: this.webinar.join_url
      }
    });
  },

  fetchWebinarDetails(id) {
    id = this.scrubWebinarId(id.toString());
    this.set("loading", true);
    this.setProperties({
      loading: true,
      error: false
    });

    ajax(`/zoom/webinars/${id}/preview`)
      .then(json => {
        this.setProperties({
          webinar: json,
          selected: true
        });
      })
      .catch(e => {
        this.setProperties({
          webinar: null,
          selected: false,
          error: true
        });
      })
      .finally(() => {
        this.set("loading", false);
      });
  },

  @discourseComputed("webinar")
  registrationRequired(webinar) {
    if (webinar.approval_type !== this.NO_REGISTRATION_REQUIRED) {
      return true;
    }
    return false;
  },

  actions: {
    selectWebinar(id) {
      this.fetchWebinarDetails(id);
    },

    clear() {
      this.set("selected", false);
    },

    insert() {
      if (this.model.addToTopic) {
        this.addWebinarToTopic();
      } else {
        this.addWebinarToComposer();
      }
      this.send("closeModal");
    }
  }
});
