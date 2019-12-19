// import { observes, on } from "discourse-common/utils/decorators";
// import { ajax } from "discourse/lib/ajax";
import Composer from "discourse/models/composer";

export default {
  name: "hook-composer",

  initialize(container) {
    const currentUser = container.lookup("current-user:main");

    // Register custom fields to be saved for new post.
    Composer.serializeOnCreate("zoom_webinar_id", "zoomWebinarId");
  },
};
