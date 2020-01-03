import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Controller.extend(ModalFunctionality, {
  webinarId: null,
  webinarIdInput: null,
  details: null,
  model: null,
  waiting: true,

  actions: {
    insert() {
      this.model.set("zoomWebinarId", this.webinarId);
      this.model.set("zoomWebinarHost", this.get("details.host"));
      this.model.set("zoomWebinarSpeakers", this.get("details.speakers"));
      this.model.set("zoomWebinarAttributes", {
        title: this.get("details.webinar.title"),
        duration: this.get("details.webinar.duration"),
        starts_at: this.get("details.webinar.starts_at"),
        ends_at: this.get("details.webinar.ends_at"),
        zoom_host_id: this.get("details.webinar.zoom_host_id"),
        password: this.get("details.webinar.password"),
        host_video: this.get("details.webinar.host_video"),
        panelists_video: this.get("details.webinar.panelists_video"),
        approval_type: this.get("details.webinar.approval_type"),
        enforce_login: this.get("details.webinar.enforce_login"),
        registrants_restrict_number: this.get("details.webinar.registrants_restrict_number"),
        meeting_authentication: this.get("details.webinar.meeting_authentication"),
        on_demand: this.get("details.webinar.on_demand"),
        join_url: this.get("details.webinar.join_url"),
      });

      this.send("closeModal");
    },

    renderPreview() {
      this.set("webinarId", this.webinarIdInput);
    },

    updateDetails(details) {
      this.set("details", details);
    }
  }
});
