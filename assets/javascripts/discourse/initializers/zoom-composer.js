import { withPluginApi } from "discourse/lib/plugin-api";
import Composer from "discourse/models/composer";
import { observes } from "discourse-common/utils/decorators";

export default {
  name: "zoom-composer",

  initialize() {
    Composer.serializeOnCreate("zoom_id", "zoomId");
    Composer.serializeOnCreate("zoom_webinar_title", "zoomWebinarTitle");
    Composer.serializeOnCreate(
      "zoom_webinar_start_date",
      "zoomWebinarStartDate"
    );

    withPluginApi("0.8.31", (api) => {
      api.decorateWidget("post:before", (dec) => {
        if (dec.canConnectComponent && dec.attrs.firstPost) {
          if (!dec.attrs.cloaked) {
            return dec.connect({
              component: "post-top-webinar",
              context: "model",
            });
          }
        }
      });

      api.modifyClass("controller:topic", {
        pluginId: "discourse-zoom",

        @observes("model.postStream.loaded")
        _addWebinarClass() {
          const webinar = this.get("model.webinar");
          if (webinar) {
            document.body.classList.add("has-webinar");
          } else {
            document.body.classList.remove("has-webinar");
          }
        },
      });
    });
  },
};
