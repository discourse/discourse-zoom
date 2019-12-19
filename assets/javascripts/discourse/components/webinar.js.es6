import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";

export default Component.extend({
  details: null,
  webinarId: null,
  loadingPreview: false,
  waitingWebinarPreview: null,
  updateDetails: null,

  init() {
    this._super(...arguments);
    this.updateDetails = this.updateDetails || (()=>{})
    this.fetchDetails();
  },

  didUpdateAttrs() {
    this._super(...arguments);
    this.fetchDetails();
  },

  @discourseComputed("details.{starts_at,details.ends_at}")
  schedule(details) {
    const start = moment(details.starts_at);
    const end = moment(details.ends_at);
    return `${start.format("kk:mm")} - ${end.format("kk:mm")}, ${start.format(
      "Do MMMM, Y"
    )}`;
  },

  fetchDetails() {
    if (!this.webinarId) return;

    this.set("loadingPreview", true);
    ajax(`/zoom/webinars/${this.webinarId}`)
      .then(results => {
        this.setProperties({
          waitingWebinarPreview: false,
          loadingPreview: false,
          details: results
        });
      })
      .finally(() => {
        this.updateDetails(this.details)
        this.set("loadingPreview", false)
      })
  }
});
