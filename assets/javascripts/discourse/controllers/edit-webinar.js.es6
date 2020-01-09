import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";

export default Controller.extend(ModalFunctionality, {
  model: null,
  newPanelist: null,
  loading: false,
  noNewPanelist: not("newPanelist"),

  @discourseComputed("model.panelists")
  excludedUsernames(panelists) {
    let usernames=panelists.map(p => p.username);
    return usernames
  },

  onShow() {
  },

  actions: {
    removePanelist(panelist) {
      console.log(panelist)
    },

    addPanelist() {

    }
  }
});
