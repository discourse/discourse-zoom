import Composer from "discourse/models/composer";

export default {
  name: "zoom-composer",

  initialize() {
    Composer.serializeOnCreate("zoom_id", "zoomId");
  }
};
