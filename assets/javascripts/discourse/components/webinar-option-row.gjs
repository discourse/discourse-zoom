import Component from "@ember/component";
import { on } from "@ember/modifier";
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
  selectWebinar(event) {
    event.preventDefault();
    this.onSelect();
  }

  <template>
    <div class="webinar-option">
      <a href {{on "click" this.selectWebinar}} class="webinar-topic">
        {{this.model.topic}}
      </a>

      <div class="webinar-schedule">
        {{this.schedule}}
      </div>

      <div class="webinar-id">
        ID:
        {{this.model.id}}
      </div>
    </div>
  </template>
}
