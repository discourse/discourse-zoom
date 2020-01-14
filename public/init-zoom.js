(function() {
  $(".d-header").hide();

  ZoomMtg.preLoadWasm();
  ZoomMtg.prepareJssdk();

  const path = window.location.pathname;
  const meetingId = path.split("/zoom/webinars/")[1].split("/sdk")[0];

  $.ajax({
    url: `/zoom/webinars/${meetingId}/signature.json`
  }).done(function(res) {
    // console.log(res);
    ZoomMtg.init({
      leaveUrl: res.topic_url,
      isSupportAV: true,
      success: function() {
        ZoomMtg.join({
          meetingNumber: res.id,
          userName: res.username,
          signature: res.signature,
          apiKey: res.api_key,
          userEmail: res.email,
          success: function(res) {
            console.log("join meeting success");
          },
          error: function(res) {
            console.log(res);
          }
        });
      },
      error: function(res) {
        console.log(res);
      }
    });
  });
})();
