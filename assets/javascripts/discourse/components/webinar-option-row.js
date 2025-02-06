import Component from "@ember/component";
import { action } from "@ember/object";
import discourseComputed from "discourse/lib/decorators";
import { formattedSchedule } from "../lib/webinar-helpers";

export default class WebinarOptionRow extends Component {
  model = null;
  onSelect = null;

  init() {
    super.init(...arguments);
    this.onSelect = this.onSelect || (() => {});
  }

  @discourseComputed("model")
  schedule(model) {
    return formattedSchedule(
      model.start_time,
      moment(model.start_time).add(model.duration, "m").toDate()
    );
  }

  @action
  selectWebinar() {
    this.onSelect();
  }
}
