import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import RemoveWebinarFromComposer from "../../components/remove-webinar-from-composer";

@tagName("div")
@classNames("composer-fields-outlet", "remove-webinar")
export default class RemoveWebinar extends Component {
  <template><RemoveWebinarFromComposer @model={{this.model}} /></template>
}
