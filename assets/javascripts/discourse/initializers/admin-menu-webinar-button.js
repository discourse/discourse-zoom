import { getOwner } from "@ember/application";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { withPluginApi } from "discourse/lib/plugin-api";
import I18n from "I18n";
import WebinarPicker from "../components/modal/webinar-picker";

const PLUGIN_ID = "discourse-zoom";

function initialize(api) {
  if (api.addTopicAdminMenuButton) {
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
  } else {
    api.decorateWidget("topic-admin-menu:adminMenuButtons", (helper) => {
      const topic = helper.attrs.topic;
      const { canManageTopic } = helper.widget.currentUser || {};

      if (!topic.isPrivateMessage && canManageTopic) {
        return {
          buttonClass: "btn-default",
          action: topic.webinar ? "removeWebinar" : "addWebinar",
          icon: "shield-alt",
          fullLabel: topic.webinar ? "zoom.remove_webinar" : "zoom.add_webinar",
        };
      }
    });

    api.modifyClass("component:topic-admin-menu-button", {
      pluginId: PLUGIN_ID,

      removeWebinar() {
        const owner = getOwner(this);
        const dialog = owner.lookup("service:dialog");
        const topicController = owner.lookup("controller:topic");
        removeWebinar(this.topic, dialog, topicController);
      },

      addWebinar() {
        const modal = getOwner(this).lookup("service:modal");
        showWebinarModal(this.topic, modal);
      },
    });
  }

  api.modifyClass("component:topic-timeline", {
    pluginId: PLUGIN_ID,

    removeWebinar() {
      const owner = getOwner(this);
      const dialog = owner.lookup("service:dialog");
      const topicController = owner.lookup("controller:topic");
      removeWebinar(this.topic, dialog, topicController);
    },

    addWebinar() {
      const modal = getOwner(this).lookup("service:modal");
      showWebinarModal(this.topic, modal);
    },
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
    message: I18n.t("zoom.confirm_remove"),
    didConfirm: () => {
      ajax(`/zoom/webinars/${topic.webinar.id}`, { type: "DELETE" })
        .then(() => {
          topic.set("webinar", null);
          topicController.set("editingTopic", false);
          document.querySelector("body").classList.remove("has-webinar");
          topic.postStream.posts[0].rebake();
        })
        .catch(popupAjaxError);
    },
  });
}
