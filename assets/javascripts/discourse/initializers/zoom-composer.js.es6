import Composer from "discourse/models/composer";

export default {
  name: "zoom-composer",

  initialize() {
    Composer.serializeOnCreate("zoom_id", "zoomId");
    Composer.serializeOnCreate("zoom_webinar_title", "zoomWebinarTitle");
    Composer.serializeOnCreate(
      "zoom_webinar_start_date",
      "zoomWebinarStartDate"
    );
  }
};
