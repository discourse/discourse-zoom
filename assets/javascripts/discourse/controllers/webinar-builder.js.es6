import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Controller.extend(ModalFunctionality, {
  webinarId: null,
  webinarIdInput: null,
  details: null,
  model: null,
  waitingWebinarPreview: true,

  actions: {
    insert() {
      this.model.set("zoomWebinarId", this.webinarId);
      this.model.set("zoomWebinarHost", this.get("details.host"));
      this.model.set("zoomWebinarSpeakers", this.get("details.speakers"));
    },

    renderPreview() {
      this.set("webinarId", this.webinarIdInput);
    },

    updateDetails(details) {
      this.set("details", details)
    }
  }
});
