import Component from "@ember/component";
import Composer from "discourse/models/composer";
import discourseComputed from "discourse-common/utils/decorators";
import showModal from "discourse/lib/show-modal";

export default Component.extend({
  model: null,

  @discourseComputed("model.action")
  visible(action) {
    return this.model.creatingTopic
  },

  actions: {
    toggleModal() {
      showModal("webinar-picker", {
        model: this.model,
        title: "zoom.webinar_picker.title"
      });
    }
  }
});
