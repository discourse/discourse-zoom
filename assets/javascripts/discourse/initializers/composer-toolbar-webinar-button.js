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
    const siteSettings = container.lookup("service:site-settings");
    const currentUser = container.lookup("service:current-user");
    if (siteSettings.zoom_enabled && currentUser) {
      withPluginApi("1.13.0", initializeWebinarButton);
    }
  },
};
