import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

function initializeAssociateWebinarButton(api) {
  api.modifyClass("controller:composer", {
    actions: {
      showAssociateWebinarModal() {
        showModal("webinar-picker", {
          model: this.model,
          title: "zoom.webinar_picker.title"
        });
      }
    }
  });

  api.addToolbarPopupMenuOptionsCallback(controller => {
    const composer = controller.model;
    if (
      composer &&
      (composer.creatingTopic || composer.get("post.post_number") === 1)
    ) {
      return {
        id: "associate_webinar_button",
        icon: "fas fa-video",
        action: "showAssociateWebinarModal",
        label: "zoom.webinar_picker.popup"
      };
    }
  });
}

export default {
  name: "add-associate-webinar-button",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    const currentUser = container.lookup("current-user:main");
    if (siteSettings.zoom_enabled && currentUser) {
      withPluginApi("0.5", initializeAssociateWebinarButton);
    }
  }
};
