import Component from "@ember/component";
import { action } from "@ember/object";

export default class RemoveWebinarFromComposer extends Component {
  model = null;

  @action
  removeWebinar() {
    this.model.set("zoomId", null);
  }
}
