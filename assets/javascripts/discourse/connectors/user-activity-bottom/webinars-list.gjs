import Component from "@ember/component";
import { LinkTo } from "@ember/routing";
import { classNames, tagName } from "@ember-decorators/component";
import { i18n } from "discourse-i18n";

@tagName("")
@classNames("user-activity-bottom-outlet", "webinars-list")
export default class WebinarsList extends Component {
  <template>
    <LinkTo @route="userActivity.webinars">
      {{i18n "zoom.webinars_title"}}
    </LinkTo>
  </template>
}
