import { apiInitializer } from "discourse/lib/api";
import { withSilencedDeprecations } from "discourse/lib/deprecated";
import Composer from "discourse/models/composer";
import RenderGlimmer from "discourse/widgets/render-glimmer";
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

  withSilencedDeprecations("discourse.post-stream-widget-overrides", () =>
    customizeWidgetPost(api)
  );
}

function customizeWidgetPost(api) {
  const PostBeforeComponent = <template>
    <PostTopWebinar @model={{@data.post}} />
  </template>;

  api.decorateWidget("post:before", (dec) => {
    if (dec.attrs.firstPost && !dec.attrs.cloaked) {
      const post = dec.widget.findAncestorModel();
      return new RenderGlimmer(
        dec.widget,
        "div.widget-connector",
        PostBeforeComponent,
        { post }
      );
    }
  });
}
