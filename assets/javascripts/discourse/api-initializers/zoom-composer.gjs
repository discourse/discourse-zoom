import { bodyClass } from "discourse/helpers/body-class";
import { apiInitializer } from "discourse/lib/api";
import Composer from "discourse/models/composer";
import RenderGlimmer from "discourse/widgets/render-glimmer";
import PostTopWebinar from "../components/post-top-webinar";

const PostBeforeComponent = <template>
  <PostTopWebinar @model={{@data.post}} />
  {{#if @data.post.topic.webinar}}
    {{bodyClass "has-webinar"}}
  {{/if}}
</template>;

export default apiInitializer("0.8", (api) => {
  Composer.serializeOnCreate("zoom_id", "zoomId");
  Composer.serializeOnCreate("zoom_webinar_title", "zoomWebinarTitle");
  Composer.serializeOnCreate("zoom_webinar_start_date", "zoomWebinarStartDate");

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
});
