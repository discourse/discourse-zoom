import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

function initializeAssociateWebinarButton(api) {
  api.modifyClass("controller:composer", {
    actions: {
      showAssociateWebinarModal() {
        this.model.set("webinarInsertCallback", picker => {
          picker.model.set("zoomWebinarId", picker.webinar.id);
          picker.model.set("zoomWebinarHost", picker.webinar.host);
          picker.model.set("zoomWebinarSpeakers", picker.webinar.speakers);
          picker.model.set("zoomWebinarAttributes", {
            title: picker.webinar.title,
            duration: picker.webinar.duration,
            starts_at: picker.webinar.starts_at,
            ends_at: picker.webinar.ends_at,
            zoom_host_id: picker.webinar.zoom_host_id,
            password: picker.webinar.password,
            host_video: picker.webinar.host_video,
            panelists_video: picker.webinar.panelists_video,
            approval_type: picker.webinar.approval_type,
            enforce_login: picker.webinar.enforce_login,
            registrants_restrict_number:
              picker.webinar.registrants_restrict_number,
            meeting_authentication: picker.webinar.meeting_authentication,
            on_demand: picker.webinar.on_demand,
            join_url: picker.webinar.join_url
          });
        });
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
