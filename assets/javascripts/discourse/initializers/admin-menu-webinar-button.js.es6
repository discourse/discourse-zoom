import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const PLUGIN_ID = "discourse-zoom";

function initialize(api) {
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
      showWebinarModal(this.topic);
    },
  });

  api.modifyClass("component:topic-timeline", {
    pluginId: PLUGIN_ID,

    removeWebinar() {
      removeWebinar(this.topic);
    },

    addWebinar() {
      showWebinarModal(this.topic);
    },
  });
}

export default {
  name: "admin-menu-webinar-button",

  initialize() {
    withPluginApi("0.8.31", initialize);
  },
};

function showWebinarModal(model) {
  model.set("addToTopic", true);
  showModal("webinar-picker", {
    model: model,
    title: "zoom.webinar_picker.title",
  });
}

function removeWebinar(topic) {
  bootbox.confirm(I18n.t("zoom.confirm_remove"), (result) => {
    if (result) {
      ajax(`/zoom/webinars/${topic.webinar.id}`, { type: "DELETE" })
        .then((response) => {
          topic.set("webinar", null);
          const topicController = Discourse.__container__.lookup(
            "controller:topic"
          );
          topicController.set("editingTopic", false);
          document.querySelector("body").classList.remove("has-webinar");
          topic.postStream.posts[0].rebake();
        })
        .catch(popupAjaxError);
    }
  });
}
