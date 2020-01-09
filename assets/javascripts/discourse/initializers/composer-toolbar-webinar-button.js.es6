import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

function initializeWebinarButton(api) {
  api.modifyClass("controller:composer", {
    actions: {
      showWebinarModal() {
        showModal("webinar-picker", {
          model: this.model,
          title: "zoom.webinar_picker.title"
        });
      }
    }
  });

  api.addToolbarPopupMenuOptionsCallback(controller => {
    const composer = controller.model;
    if (composer && composer.creatingTopic) {
      return {
        id: "associate_webinar_button",
        icon: "video",
        action: "showWebinarModal",
        label: "zoom.webinar_picker.popup"
      };
    }
  });
}

export default {
  name: "composer-toolbar-webinar-button",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    const currentUser = container.lookup("current-user:main");
    if (siteSettings.zoom_enabled && currentUser) {
      withPluginApi("0.5", initializeWebinarButton);
    }
  }
};
