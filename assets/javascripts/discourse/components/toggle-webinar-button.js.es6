import Component from "@ember/component";
import showModal from "discourse/lib/show-modal";

export default Component.extend({
  model: null,

  actions: {
    toggleModal() {
      showModal("webinar-builder", {
        model: this.model,
        title: "zoom.webinar_builder.title"
      });
    }
  }
});
