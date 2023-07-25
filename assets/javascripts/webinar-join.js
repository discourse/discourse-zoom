/* global ZoomMtg:true */

window.onload = () => {
  (function () {
    document.querySelector(".d-header").style.display = "none";

    ZoomMtg.preLoadWasm();
    ZoomMtg.prepareJssdk();

    const path = window.location.pathname;
    const meetingId = path.split("/zoom/webinars/")[1].split("/sdk")[0];
    let getParams = function (url) {
      let params = {};
      let parser = document.createElement("a");
      parser.href = url;
      let query = parser.search.substring(1);
      let vars = query.split("&");
      for (let i = 0; i < vars.length; i++) {
        let pair = vars[i].split("=");
        params[pair[0]] = decodeURIComponent(pair[1]);
      }
      return params;
    };

    let request = new XMLHttpRequest();
    request.open("GET", `/zoom/webinars/${meetingId}/signature.json`, true);

    request.onload = function () {
      if (this.status >= 200 && this.status < 400) {
        let res = JSON.parse(this.response);
        ZoomMtg.init({
          leaveUrl: res.topic_url,
          isSupportAV: true,
          // audioPanelAlwaysOpen: false,
          // disableJoinAudio: true,
          disableCallOut: true,
          success: function () {
            ZoomMtg.join({
              meetingNumber: res.id,
              userName: res.username,
              signature: res.signature,
              sdkKey: res.sdk_key,
              userEmail: res.email,
              passWord: res.password || "",
              success: () => {},
              error: (join_result) => {
                if (join_result.errorCode === 1) {
                  const params = getParams(window.location.href);
                  if (params.fallback) {
                    window.setTimeout(() => {
                      let btn = `<a href="https://zoom.us/j/${res.id}" id="zoom-fallback" class="zm-btn zm-btn-legacy zm-btn--primary zm-btn__outline--blue" >Launch in Zoom</a>`;
                      document.querySelector(
                        ".zm-modal-body-content .content"
                      ).innerHTML = `<p>There was a problem launching the Zoom SDK. Click the button below to try joining the event in Zoom.</p> ${btn}`;
                    }, 200);
                  }
                }
              },
            });
          },
          error: () => {},
        });
      } else {
        // eslint-disable-next-line no-console
        console.error();
      }
    };

    // request.onerror = function() {};
    request.send();
  })();
};
