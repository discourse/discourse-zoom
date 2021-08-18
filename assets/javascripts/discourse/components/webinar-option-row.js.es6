import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { formattedSchedule } from "../lib/webinar-helpers";

export default Component.extend({
  model: null,
  onSelect: null,

  init() {
    this._super(...arguments);
    this.onSelect = this.onSelect || (() => {});
  },

  @discourseComputed("model")
  schedule(model) {
    return formattedSchedule(
      model.start_time,
      moment(model.start_time).add(model.duration, "m").toDate()
    );
  },

  actions: {
    selectWebinar() {
      this.onSelect();
    },
  },
});
