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
    let usernames = panelists.map(p => p.username);
    return usernames;
  },

  @discourseComputed("loading", "newPanelist")
  addingDisabled(loading, panelist) {
    return loading || !panelist;
  },

  actions: {
    removePanelist(panelist) {
      this.set("loading", true);
      ajax(
        `/zoom/webinars/${this.model.zoom_id}/panelists/${panelist.username}`,
        {
          type: "DELETE"
        }
      )
        .then(results => {
          this.store.find("webinar", this.model.zoom_id).then(webinar => {
            this.set("model", webinar);
          });
        })
        .finally(() => {
          this.set("loading", false);
        });
    },

    addPanelist() {
      this.set("loading", true);
      ajax(
        `/zoom/webinars/${this.model.zoom_id}/panelists/${this.newPanelist}`,
        {
          type: "PUT"
        }
      )
        .then(results => {
          this.set("newPanelist", null);
          this.store.find("webinar", this.model.zoom_id).then(webinar => {
            this.set("model", webinar);
          });
        })
        .finally(() => {
          this.set("loading", false);
        });
    }
  }
});
