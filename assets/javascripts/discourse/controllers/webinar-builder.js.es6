import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";

export default Controller.extend(ModalFunctionality, {
  webinarId: null,
  model: null,
  details: null,

  onClose() {},

  actions: {
    save() {
      ajax(`zoom/webinars/${this.webinarId}`).then(results => {
        this.set("details", results);
      }).then(() => {
        this.model.set("zoomWebinarId", this.webinarId)
      })
    }
  }
});
