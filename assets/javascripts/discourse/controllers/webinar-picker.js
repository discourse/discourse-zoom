import Controller, { inject as controller } from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

const NONZOOM = "nonzoom";

export default Controller.extend(ModalFunctionality, {
  topicController: controller("topic"),
  webinarId: null,
  webinarIdInput: null,
  webinar: null,
  model: null,
  loading: false,
  selected: false,
  addingPastWebinar: false,
  pastStartDate: moment(new Date(), "YYYY-MM-DD").toDate(),
  pastWebinarTitle: "",
  allWebinars: null,
  error: false,
  NO_REGISTRATION_REQUIRED: 2,

  onShow() {
    if (!this.webinar) {
      if (this.model && this.model.get("webinar.zoom_id")) {
        this.set("webinarId", this.model.get("webinar.zoom_id"));
        this.set("webinarIdInput", this.model.get("webinar.zoom_id"));
      }

      if (!this.selected) {
        ajax("/zoom/webinars").then((results) => {
          if (results && results.webinars) {
            this.set("allWebinars", results.webinars);
          }
        });
      }
    }
  },

  onClose() {
    this.setProperties({
      allWebinars: null,
      selected: false,
      webinarIdInput: null,
      webinar: null,
      error: false,
      addingPastWebinar: false,
    });
  },

  scrubWebinarId(webinarId) {
    return webinarId.replace(/-|\s/g, "");
  },

  addWebinarToTopic() {
    const webinarId = this.webinar ? this.webinar.id : NONZOOM;

    let data = {};

    if (this.pastWebinarTitle && this.pastStartDate) {
      data = {
        zoom_title: this.pastWebinarTitle,
        zoom_start_date: moment(this.pastStartDate).format(),
      };
    }

    ajax(`/zoom/t/${this.model.id}/webinars/${webinarId}`, {
      type: "PUT",
      data,
    })
      .then((results) => {
        this.store.find("webinar", results.id).then((webinar) => {
          this.model.set("webinar", webinar);
        });
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.set("loading", false);
        this.topicController.set("editingTopic", false);
        this.model.postStream.posts[0].rebake();
        document.querySelector("body").classList.add("has-webinar");
      });
  },

  addWebinarToComposer() {
    this.model.set("zoomId", this.webinar.id);
    this.model.set("zoomWebinarTitle", this.webinar.title);
  },

  fetchWebinarDetails(id) {
    id = this.scrubWebinarId(id.toString());
    this.set("loading", true);
    this.setProperties({
      loading: true,
      error: false,
    });

    ajax(`/zoom/webinars/${id}/preview`)
      .then((json) => {
        this.setProperties({
          webinar: json,
          selected: true,
        });
      })
      .catch(() => {
        this.setProperties({
          webinar: null,
          selected: false,
          error: true,
        });
      })
      .finally(() => {
        this.set("loading", false);
      });
  },

  @discourseComputed("webinar")
  webinarError(webinar) {
    if (webinar.approval_type !== this.NO_REGISTRATION_REQUIRED) {
      return I18n.t("zoom.no_registration_required");
    }
    if (webinar.existing_topic) {
      return I18n.t("zoom.webinar_existing_topic", {
        topic_id: webinar.existing_topic.topic_id,
      });
    }
    return false;
  },

  @discourseComputed("pastWebinarTitle", "pastStartDate")
  pastWebinarDisabled(pastWebinarTitle, pastStartDate) {
    return !pastWebinarTitle || !pastStartDate;
  },

  actions: {
    selectWebinar(id) {
      this.fetchWebinarDetails(id);
    },

    clear() {
      this.set("selected", false);
    },

    insert() {
      if (this.model.addToTopic) {
        this.addWebinarToTopic();
      } else {
        this.addWebinarToComposer();
      }
      this.send("closeModal");
    },

    addPastWebinar() {
      this.model.set("zoomId", NONZOOM);
      this.model.set("zoomWebinarTitle", this.pastWebinarTitle);
      this.model.set(
        "zoomWebinarStartDate",
        moment(this.pastStartDate).format()
      );
      if (this.model.addToTopic) {
        this.addWebinarToTopic();
      }
      this.send("closeModal");
    },

    showPastWebinarForm() {
      this.set("addingPastWebinar", true);
      this.set("selected", false);
    },

    onChangeDate(date) {
      if (!date) {
        return;
      }

      this.set("pastStartDate", date);
    },
  },
});
