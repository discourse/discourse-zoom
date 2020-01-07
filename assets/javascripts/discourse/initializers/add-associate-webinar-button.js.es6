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

  api.addToolbarPopupMenuOptionsCallback(() => {
    return {
      id: "associate_webinar_button",
      icon: "far-thumbs-up",
      action: "showAssociateWebinarModal",
      label: "zoom.webinar_picker.create"
    };
  });
}

export default {
  name: "add-associate-webinar-button",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    const currentUser = container.lookup("current-user:main");
    // HERE I want to use the composer's state to add conditionals below.
    const composerController = container.lookup("controller:composer");
    if (
      siteSettings.zoom_enabled &&
      currentUser
    ) {
      withPluginApi("0.5", initializeAssociateWebinarButton);
    }
  }
};
