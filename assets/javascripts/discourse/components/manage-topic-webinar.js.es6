import discourseComputed from "discourse-common/utils/decorators";
import { alias } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";
import showModal from "discourse/lib/show-modal";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Component from "@ember/component";

export default Component.extend({
  model: null,
  webinar: alias("model.webinar"),
  loading: false,

  init() {
    this._super(...arguments);
  },

  actions: {
    addWebinar() {
      this.set("loading", true);
      this.model.set("addToTopic", true);
      showModal("webinar-picker", {
        model: this.model,
        title: "zoom.webinar_picker.title"
      });
    },

    removeWebinar() {
      return bootbox.confirm(I18n.t("zoom.confirm_remove"), result => {
        if (result) {
          this.set("loading", true);
          ajax(`/zoom/webinars/${this.webinar.zoom_id}`, { type: "DELETE" })
            .then(response => {
              this.set("webinar", null);
              const topicController = Discourse.__container__.lookup(
                "controller:topic"
              );
              topicController.set("editingTopic", false);
            })
            .catch(popupAjaxError)
            .finally(() => {
              this.set("loading", false);
            });
        }
      });
    }
  }
});
