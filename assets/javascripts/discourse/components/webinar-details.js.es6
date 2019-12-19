import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";

export default Component.extend({
  details: null,
  webinarId: null,
  model: null,

  @discourseComputed("details.{starts_at,details.ends_at}")
  schedule(details) {
    const start = moment(details.starts_at);
    const end = moment(details.ends_at);
    return `${start.format("kk:mm")} - ${end.format("kk:mm")}, ${start.format(
      "Do MMMM, Y"
    )}`;
  },

  didUpdateAttrs() {
    this._super(...arguments);
    if (!this.webinarId) return;
    
    ajax(`zoom/webinars/${this.webinarId}`).then(results => {
      this.set("details", results);
    }).then(() => {
      this.model.set("zoomWebinarId", this.webinarId)
    });
  }
});
