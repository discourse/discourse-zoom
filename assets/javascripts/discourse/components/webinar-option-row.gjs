/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { on } from "@ember/modifier";
import { action, computed } from "@ember/object";
import { formattedSchedule } from "../lib/webinar-helpers";

export default class WebinarOptionRow extends Component {
  model = null;
  onSelect = null;

  init() {
    super.init(...arguments);
    this.onSelect = this.onSelect || (() => {});
  }

  @computed("model")
  get schedule() {
    return formattedSchedule(
      this.model.start_time,
      moment(this.model.start_time).add(this.model.duration, "m").toDate()
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
