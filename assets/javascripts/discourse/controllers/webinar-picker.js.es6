import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { formattedSchedule } from "../lib/webinar-helpers";
import { ajax } from "discourse/lib/ajax";

export default Controller.extend(ModalFunctionality, {
  webinarId: null,
  webinarIdInput: null,
  webinar: null,
  model: null,
  waiting: true,

  allWebinars: null,
  selectedWebinar: null,

  onShow() {
    if (!this.webinar) {
      if (this.model.get("webinar.zoom_id")) {
        this.set("webinarId", this.model.get("webinar.zoom_id"))
        this.set("webinarIdInput", this.model.get("webinar.zoom_id"))
      }

      if (!this.webinarId) {
        ajax("/zoom/webinars").then(results => {
          if (results && results.webinars) {
            this.set("allWebinars", results.webinars);
          }
        });
      }
    }
  },

  scrubWebinarId(webinarId) {
    return webinarId.replace(/-|\s/g,"");
  },

  actions: {
    selectWebinar(webinarId) {
      this.set("webinarId", this.scrubWebinarId(webinarId));
    },

    clear() {
      this.set("webinarId", null);
    },

    insert() {
      this.model.set("zoomWebinarId", this.webinarId);
      this.model.set("zoomWebinarHost", this.get("webinar.host"));
      this.model.set("zoomWebinarSpeakers", this.get("webinar.speakers"));
      this.model.set("zoomWebinarAttributes", {
        title: this.get("webinar.title"),
        duration: this.get("webinar.duration"),
        starts_at: this.get("webinar.starts_at"),
        ends_at: this.get("webinar.ends_at"),
        zoom_host_id: this.get("webinar.zoom_host_id"),
        password: this.get("webinar.password"),
        host_video: this.get("webinar.host_video"),
        panelists_video: this.get("webinar.panelists_video"),
        approval_type: this.get("webinar.approval_type"),
        enforce_login: this.get("webinar.enforce_login"),
        registrants_restrict_number: this.get(
          "webinar.registrants_restrict_number"
        ),
        meeting_authentication: this.get("webinar.meeting_authentication"),
        on_demand: this.get("webinar.on_demand"),
        join_url: this.get("webinar.join_url")
      });

      this.send("closeModal");
    },

    previewFromInput() {
      this.set("webinarId", this.scrubWebinarId(this.webinarIdInput));
    },

    updateDetails(webinar) {
      this.set("webinar", webinar);
    }
  }
});
