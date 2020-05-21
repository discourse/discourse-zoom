import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";
import { makeArray } from "discourse-common/lib/helpers";

export default Controller.extend(ModalFunctionality, {
  model: null,
  newPanelist: null,
  loading: false,
  noNewPanelist: not("newPanelist"),
  newVideoUrl: null,

  @discourseComputed("model.video_url", "newVideoUrl", "loading")
  canSaveVideoUrl(saved, newValue, loading) {
    if (saved === newValue || loading) return true;

    saved = saved === null ? "" : saved;
    newValue = newValue === null ? "" : newValue;
    return saved === newValue;
  },

  @discourseComputed("model.panelists", "model.host")
  excludedUsernames(panelists, host) {
    return panelists.concat(makeArray(host)).map((p) => p.username);
  },

  @discourseComputed("loading", "newPanelist")
  addingDisabled(loading, panelist) {
    return loading || !panelist;
  },

  @discourseComputed("loading", "title", "pastStartDate")
  updateDetailsDisabled(loading, title, pastStartDate) {
    return (
      loading ||
      (this.model.title === title && this.model.starts_at === pastStartDate)
    );
  },

  onShow() {
    this.setProperties({
      newVideoUrl: this.model.video_url,
      hostUsername: this.model.host ? this.model.host.username : null,
      title: this.model.title,
      pastStartDate: this.model.starts_at,
    });

    if (this.model.zoom_id === "nonzoom") {
      this.set("nonZoomWebinar", true);
    }
  },

  actions: {
    saveVideoUrl() {
      this.set("loading", true);
      ajax(`/zoom/webinars/${this.model.id}/video_url.json`, {
        data: { video_url: this.newVideoUrl },
        type: "PUT",
      })
        .then((results) => {
          this.model.set("video_url", results.video_url);
        })
        .finally(() => {
          this.set("loading", false);
        });
    },

    resetVideoUrl() {
      this.set("newVideoUrl", this.model.video_url);
    },

    removePanelist(panelist) {
      this.set("loading", true);
      ajax(
        `/zoom/webinars/${this.model.id}/panelists/${panelist.username}.json`,
        {
          type: "DELETE",
        }
      )
        .then((results) => {
          this.store.find("webinar", this.model.id).then((webinar) => {
            this.set("model", webinar);
          });
        })
        .catch(popupAjaxError)
        .finally(() => {
          this.set("loading", false);
        });
    },

    addPanelist() {
      this.set("loading", true);
      ajax(
        `/zoom/webinars/${this.model.id}/panelists/${this.newPanelist}.json`,
        {
          type: "PUT",
        }
      )
        .then((results) => {
          this.set("newPanelist", null);
          this.store.find("webinar", this.model.id).then((webinar) => {
            this.set("model", webinar);
          });
        })
        .catch(popupAjaxError)
        .finally(() => {
          this.set("loading", false);
        });
    },

    onChangeDate(date) {
      if (!date) return;

      this.set("pastStartDate", date);
    },

    onChangeHost() {
      this.set("loading", true);
      let hostUsername = this.hostUsername,
        postType = "PUT";

      if (this.hostUsername.length === 0) {
        hostUsername = this.model.host.username;
        postType = "DELETE";
      }

      ajax(
        `/zoom/webinars/${this.model.id}/nonzoom_host/${hostUsername}.json`,
        {
          type: postType,
        }
      )
        .then((results) => {
          this.store.find("webinar", this.model.id).then((webinar) => {
            this.set("model", webinar);
          });
        })
        .catch(popupAjaxError)
        .finally(() => {
          this.set("loading", false);
        });
    },

    updateDetails() {
      this.set("loading", true);

      ajax(`/zoom/webinars/${this.model.id}/nonzoom_details.json`, {
        type: "PUT",
        data: {
          title: this.title,
          past_start_date: moment(this.pastStartDate).format(),
        },
      })
        .then(() => {
          this.set("model.title", this.title);
          this.set("model.starts_at", this.pastStartDate);
        })
        .catch(popupAjaxError)
        .finally(() => {
          this.set("loading", false);
        });
    },
  },
});
