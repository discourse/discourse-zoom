import Component from "@ember/component";

export default Component.extend({
  model: null,

  actions: {
    removeWebinar() {
      this.model.set("zoomWebinarId", null);
    }
  }
});
