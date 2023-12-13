import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { getOwner } from "discourse-common/lib/get-owner";
import I18n from "I18n";
import WebinarPicker from "../components/modal/webinar-picker";

const PLUGIN_ID = "discourse-zoom";

function initialize(api) {
  const modal = api.container.lookup("service:modal");
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
      removeWebinar(this.topic);
    },

    addWebinar() {
      showWebinarModal(this.topic, modal);
    },
  });

  api.modifyClass("component:topic-timeline", {
    pluginId: PLUGIN_ID,

    removeWebinar() {
      removeWebinar(this.topic);
    },

    addWebinar() {
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
  modal.show(WebinarPicker, { model: { topic } });
}

function removeWebinar(topic) {
  const dialog = getOwner(this).lookup("service:dialog");
  dialog.confirm({
    message: I18n.t("zoom.confirm_remove"),
    didConfirm: () => {
      ajax(`/zoom/webinars/${topic.webinar.id}`, { type: "DELETE" })
        .then(() => {
          topic.set("webinar", null);
          const topicController = getOwner(this).lookup("controller:topic");
          topicController.set("editingTopic", false);
          document.querySelector("body").classList.remove("has-webinar");
          topic.postStream.posts[0].rebake();
        })
        .catch(popupAjaxError);
    },
  });
}
