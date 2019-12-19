import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";

export default Component.extend({
  details: null,
  webinarId: null,
  composer: null,
  preview: false,

  init() {
    this._super(...arguments);
    this.fetchDetails()
  },

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
    if (this.preview || !this.webinarId) return;

    this.fetchDetails()
  },

  fetchDetails() {
    ajax(`/zoom/webinars/${this.webinarId}`).then(results => {
      this.set("details", results);
    }).then(() => {
      if (this.preview)
        this.composer.set("zoomWebinarId", this.webinarId)
    });
  },
});
