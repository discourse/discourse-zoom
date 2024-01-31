import { withPluginApi } from "discourse/lib/plugin-api";
import WebinarPicker from "../components/modal/webinar-picker";

function initializeWebinarButton(api) {
  const composerService = api.container.lookup("service:composer");
  const modal = api.container.lookup("service:modal");

  api.addComposerToolbarPopupMenuOption({
    condition: (composer) => {
      return composer.model && composer.model.creatingTopic;
    },
    icon: "video",
    label: "zoom.webinar_picker.button",
    action: () => {
      modal.show(WebinarPicker, {
        model: {
          topic: composerService.model,
          setWebinar: (value) => composerService.model.set("webinar", value),
          setZoomId: (value) => composerService.model.set("zoomId", value),
          setWebinarTitle: (value) =>
            composerService.model.set("zoomWebinarTitle", value),
          setWebinarStartDate: (value) =>
            composerService.model.set("zoomWebinarStartDate", value),
        },
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
