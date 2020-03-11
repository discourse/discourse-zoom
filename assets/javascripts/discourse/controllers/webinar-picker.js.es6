import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { formattedSchedule } from "../lib/webinar-helpers";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed from "discourse-common/utils/decorators";

export default Controller.extend(ModalFunctionality, {
  webinarId: null,
  webinarIdInput: null,
  webinar: null,
  model: null,
  loading: false,
  selected: false,
  addingPastWebinar: false,
  pastStartDate: "",
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
        ajax("/zoom/webinars").then(results => {
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
      addingPastWebinar: false
    });
  },

  scrubWebinarId(webinarId) {
    return webinarId.replace(/-|\s/g, "");
  },

  addWebinarToTopic() {
    ajax(`/zoom/t/${this.model.id}/webinars/${this.webinar.id}`, {
      type: "PUT"
    })
      .then(results => {
        this.store.find("webinar", results.id).then(webinar => {
          this.model.set("webinar", webinar);
        });
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.set("loading", false);
        const topicController = Discourse.__container__.lookup(
          "controller:topic"
        );
        topicController.set("editingTopic", false);
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
      error: false
    });

    ajax(`/zoom/webinars/${id}/preview`)
      .then(json => {
        this.setProperties({
          webinar: json,
          selected: true
        });
      })
      .catch(e => {
        this.setProperties({
          webinar: null,
          selected: false,
          error: true
        });
      })
      .finally(() => {
        this.set("loading", false);
      });
  },

  @discourseComputed("webinar")
  registrationRequired(webinar) {
    if (webinar.approval_type !== this.NO_REGISTRATION_REQUIRED) {
      return true;
    }
    return false;
  },

  @discourseComputed("pastWebinarTitle", "pastStartDate")
  pastWebinarDisabled(title, startDate) {
    console.log(title.length);
    console.log(startDate.length);
    return !title.length || !startDate.length;
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

    onChangeDate(date) {
      this.set("startDate", date);
    },

    addPastWebinar() {
      this.model.set("zoomId", "nonzoom");
      this.model.set("zoomWebinarTitle", this.pastWebinarTitle);
      this.model.set("zoomWebinarStartDate", this.pastStartDate);
      this.send("closeModal");
    },

    showPastWebinarForm() {
      this.set("addingPastWebinar", true);
      this.set("selected", false);
    }
  }
});
