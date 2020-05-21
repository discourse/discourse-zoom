import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";

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

  @discourseComputed("model.panelists")
  excludedUsernames(panelists) {
    let usernames = panelists.map((p) => p.username);
    return usernames;
  },

  @discourseComputed("loading", "newPanelist")
  addingDisabled(loading, panelist) {
    return loading || !panelist;
  },

  @discourseComputed("loading", "hostUsername")
  addingHostDisabled(loading, hostUsername) {
    return (
      loading || !hostUsername || hostUsername === this.model.host.username
    );
  },

  onShow() {
    this.setProperties({
      newVideoUrl: this.model.video_url,
      hostUsername: this.model.host.username,
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

    addHost() {
      this.set("loading", true);
      ajax(
        `/zoom/webinars/${this.model.id}/nonzoom_host/${this.hostUsername}.json`,
        {
          type: "PUT",
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

    onChangeDate(date) {
      if (!date) return;

      this.set("pastStartDate", date);
    },

    updateDetails() {
      ajax(`/zoom/webinars/${this.model.id}/nonzoom_details.json`, {
        type: "PUT",
        data: {
          title: this.title,
          past_start_date: moment(this.pastStartDate).format(),
        },
      })
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
  },
});
