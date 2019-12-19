import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Controller.extend(ModalFunctionality, {
  webinarId: null,
  webinarIdInput: null,
  details: null,

  onClose() {},

  actions: {
    save() {},

    renderPreview() {
      this.set("webinarId", this.webinarIdInput);
    }
  }
});
