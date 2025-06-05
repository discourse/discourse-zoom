import Component from "@ember/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";

export default class RemoveWebinarFromComposer extends Component {
  model = null;

  @action
  removeWebinar() {
    this.model.set("zoomId", null);
  }

  <template>
    {{#if this.model.zoomId}}
      <div class="composer-webinar">
        <span class="webinar-label">Webinar - </span>

        <span class="webinar-title">
          {{this.model.zoomWebinarTitle}}
        </span>

        <DButton
          class="cancel no-text"
          @action={{this.removeWebinar}}
          @icon="xmark"
          @title="zoom.remove"
        />
      </div>
    {{/if}}
  </template>
}
