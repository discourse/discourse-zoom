import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default Controller.extend(ModalFunctionality, {
  webinarId: null,
  details: null,

  onClose() {
  },

  actions: {
    save() {
      ajax(`zoom/webinars/${this.webinarId}`)
        .then((results) => {
          debugger;
          this.set('details', results);
        })
    }
  }
});
