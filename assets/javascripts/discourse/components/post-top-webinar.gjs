import Webinar from "./webinar";

const PostTopWebinar = <template>
  {{#if @model.topic.webinar}}
    <div class="webinar-banner">
      <Webinar @topic={{@model.topic}} @webinarId={{@model.topic.webinar.id}} />
    </div>
  {{/if}}
</template>;

export default PostTopWebinar;
