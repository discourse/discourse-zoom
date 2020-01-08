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
        this.set("webinarId", this.model.get("webinar.zoom_id"));
        this.set("webinarIdInput", this.model.get("webinar.zoom_id"));
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
    return webinarId.replace(/-|\s/g, "");
  },

  actions: {
    selectWebinar(webinarId) {
      this.set("webinarId", this.scrubWebinarId(webinarId.toString()));
    },

    clear() {
      this.set("webinarId", null);
    },

    insert() {
      this.model.webinarInsertCallback(this);
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
