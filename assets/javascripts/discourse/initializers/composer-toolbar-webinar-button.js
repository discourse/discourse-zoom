import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

function initializeWebinarButton(api) {
  const composerService = api.container.lookup("service:composer");

  api.addComposerToolbarPopupMenuOption({
    condition: (composer) => {
      return composer.model && composer.model.creatingTopic;
    },
    icon: "video",
    label: "zoom.webinar_picker.button",
    action: () => {
      showModal("webinar-picker", {
        model: composerService.model,
        title: "zoom.webinar_picker.title",
      });
    },
  });
}

export default {
  name: "composer-toolbar-webinar-button",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    const currentUser = container.lookup("current-user:main");
    if (siteSettings.zoom_enabled && currentUser) {
      withPluginApi("1.15.0", initializeWebinarButton);
    }
  },
};
