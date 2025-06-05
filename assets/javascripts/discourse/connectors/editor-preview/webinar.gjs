import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import Webinar0 from "../../components/webinar";

@tagName("div")
@classNames("editor-preview-outlet", "webinar")
export default class Webinar extends Component {
  <template><Webinar0 @webinarId={{this.model.zoom_webinar_id}} /></template>
}
