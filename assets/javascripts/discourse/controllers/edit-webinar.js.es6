import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not, equal } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";

export default Controller.extend(ModalFunctionality, {
  model: null,
  newPanelist: null,
  loading: false,
  noNewPanelist: not("newPanelist"),
  newVideoUrl: null,
  // videoUrlClean: equal("model.video_url", "newVideoUrl"),

  @discourseComputed("model.video_url", "newVideoUrl", "loading")
  videoUrlClean(saved, newValue, loading) {
    if (saved === newValue || loading) return true;

    saved = saved === null ? "" : saved;
    newValue = newValue === null ? "" : newValue;
    return saved === newValue;
  },

  @discourseComputed("model.panelists")
  excludedUsernames(panelists) {
    let usernames = panelists.map(p => p.username);
    return usernames;
  },

  @discourseComputed("loading", "newPanelist")
  addingDisabled(loading, panelist) {
    return loading || !panelist;
  },

  onShow() {
    this.set("newVideoUrl", this.model.video_url);
  },

  actions: {
    saveVideoUrl() {
      this.set("loading", true);
      ajax(`/zoom/webinars/${this.model.id}/video_url.json`, {
        data: { video_url: this.newVideoUrl },
        type: "PUT"
      })
        .then(results => {
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
          type: "DELETE"
        }
      )
        .then(results => {
          this.store.find("webinar", this.model.id).then(webinar => {
            this.set("model", webinar);
          });
        })
        .finally(() => {
          this.set("loading", false);
        });
    },

    addPanelist() {
      this.set("loading", true);
      ajax(
        `/zoom/webinars/${this.model.id}/panelists/${this.newPanelist}.json`,
        {
          type: "PUT"
        }
      )
        .then(results => {
          this.set("newPanelist", null);
          this.store.find("webinar", this.model.id).then(webinar => {
            this.set("model", webinar);
          });
        })
        .finally(() => {
          this.set("loading", false);
        });
    }
  }
});
