import UserTopicListRoute from "discourse/routes/user-topic-list";

export default class UserActivityWebinars extends UserTopicListRoute {
  userActionType = null;
  noContentHelpKey = "zoom.no_user_webinars";

  model() {
    return this.store.findFiltered("topicList", {
      filter: `topics/webinar-registrations/${this.modelFor("user").get(
        "username_lower"
      )}`,
    });
  }
}
