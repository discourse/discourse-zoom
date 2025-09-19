import { apiInitializer } from "discourse/lib/api";
import Composer from "discourse/models/composer";
import PostTopWebinar from "../components/post-top-webinar";

export default apiInitializer((api) => {
  Composer.serializeOnCreate("zoom_id", "zoomId");
  Composer.serializeOnCreate("zoom_webinar_title", "zoomWebinarTitle");
  Composer.serializeOnCreate("zoom_webinar_start_date", "zoomWebinarStartDate");

  customizePost(api);
});

function customizePost(api) {
  api.renderBeforeWrapperOutlet(
    "post-article",
    <template><PostTopWebinar @model={{@post}} /></template>
  );
}
