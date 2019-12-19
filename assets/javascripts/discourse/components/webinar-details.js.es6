import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  details: null,

  @discourseComputed("details.{starts_at,details.ends_at}")
  schedule(details) {
    const start = moment(details.starts_at);
    const end = moment(details.ends_at);
    return `${start.format("kk:mm")} - ${end.format("kk:mm")}, ${start.format(
      "Do MMMM, Y"
    )}`;
  },

  actions: {}
});
