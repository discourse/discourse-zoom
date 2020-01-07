import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import showModal from "discourse/lib/show-modal";

export default Component.extend({
  model: null,

  actions: {
    toggleModal() {
      showModal("webinar-picker", {
        model: this.model,
        title: "zoom.webinar_picker.title"
      });
    }
  }
})
