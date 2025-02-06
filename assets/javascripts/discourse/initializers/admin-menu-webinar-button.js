import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import WebinarPicker from "../components/modal/webinar-picker";

function initialize(api) {
  api.addTopicAdminMenuButton((topic) => {
    const canManageTopic = api.getCurrentUser()?.canManageTopic;

    if (!topic.isPrivateMessage && canManageTopic) {
      return {
        icon: "shield-alt",
        label: topic.get("webinar")
          ? "zoom.remove_webinar"
          : "zoom.add_webinar",
        action: () => {
          if (topic.get("webinar")) {
            const dialog = api.container.lookup("service:dialog");
            const topicController = api.container.lookup("controller:topic");
            removeWebinar(topic, dialog, topicController);
          } else {
            const modal = api.container.lookup("service:modal");
            showWebinarModal(topic, modal);
          }
        },
      };
    }
  });
}

export default {
  name: "admin-menu-webinar-button",

  initialize() {
    withPluginApi("0.8.31", initialize);
  },
};

function showWebinarModal(topic, modal) {
  topic.set("addToTopic", true);
  modal.show(WebinarPicker, {
    model: {
      topic,
      setWebinar: (value) => topic.set("webinar", value),
      setZoomId: (value) => topic.set("zoomId", value),
      setWebinarTitle: (value) => topic.set("zoomWebinarTitle", value),
      setWebinarStartDate: (value) => topic.set("zoomWebinarStartDate", value),
    },
  });
}

function removeWebinar(topic, dialog, topicController) {
  dialog.confirm({
    message: i18n("zoom.confirm_remove"),
    didConfirm: () => {
      ajax(`/zoom/webinars/${topic.webinar.id}`, { type: "DELETE" })
        .then(() => {
          topic.set("webinar", null);
          topicController.set("editingTopic", false);
          document.body.classList.remove("has-webinar");
          topic.postStream.posts[0].rebake();
        })
        .catch(popupAjaxError);
    },
  });
}
