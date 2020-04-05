(function() {
  $(".d-header").hide();

  ZoomMtg.preLoadWasm();
  ZoomMtg.prepareJssdk();

  const path = window.location.pathname;
  const meetingId = path.split("/zoom/webinars/")[1].split("/sdk")[0];

  var getParams = function(url) {
    var params = {};
    var parser = document.createElement("a");
    parser.href = url;
    var query = parser.search.substring(1);
    var vars = query.split("&");
    for (var i = 0; i < vars.length; i++) {
      var pair = vars[i].split("=");
      params[pair[0]] = decodeURIComponent(pair[1]);
    }
    return params;
  };

  $.ajax({
    url: `/zoom/webinars/${meetingId}/signature.json`
  }).done(function(res) {
    ZoomMtg.init({
      leaveUrl: res.topic_url,
      isSupportAV: true,
      // audioPanelAlwaysOpen: false,
      // disableJoinAudio: true,
      // disableCallOut: true,
      success: function() {
        ZoomMtg.join({
          meetingNumber: res.id,
          userName: res.username,
          signature: res.signature,
          apiKey: res.api_key,
          userEmail: res.email,
          success: function(res) {
            setTimeout(function() {
              $("#dialog-join .title.tab:nth-child(2) button").click(); // default to Computer Audio
            }, 200);
          },
          error: function(join_result) {
            console.log(res);
            if (join_result.errorCode === 1) {
              const params = getParams(window.location.href);
              if (params.fallback) {
                window.setTimeout(() => {
                  let btn = `<a href="https://zoom.us/j/${res.id}" id="zoom-fallback" class="zm-btn zm-btn-legacy zm-btn--primary zm-btn__outline--blue" >Launch in Zoom</a>`;
                  $(".zm-modal-body-content .content").html(
                    `<p>There was a problem launching the Zoom SDK. Click the button below to try joining the event in Zoom.</p> ${btn}`
                  );
                }, 200);
              }
            }
          }
        });
      },
      error: function(res) {
        console.log(res);
      }
    });
  });
})();
