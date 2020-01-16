class ZoomApiStubs
  def self.get_webinar(id, host_id=123)
    {
      "agenda": "",
      "created_at": "2020-01-06T17:14:44Z",
      "duration": 120,
      "host_id": host_id,
      "id": id,
      "join_url": "https://zoom.us/j/243200?",
      "password": "828943",
      "settings": {
        "allow_multiple_devices": true,
        "alternative_hosts": "",
        "approval_type": 2,
        "audio": "telephony",
        "authentication_domains": "",
        "authentication_option": "signin_tzr4QYF8ng",
        "auto_recording": "none",
        "close_registration": true,
        "contact_email": "mark.vanlandingham@discourse.org",
        "contact_name": "Mark VanLandingham",
        "enforce_login": true,
        "enforce_login_domains": "",
        "global_dial_in_countries": [
          "US"
        ],
        "global_dial_in_numbers": [
          {
            "city": "New York",
            "country": "US",
            "country_name": "US",
            "number": "+1 9292056099",
            "type": "toll"
          },
          {
            "city": "San Jose",
            "country": "US",
            "country_name": "US",
            "number": "+1 6699006833",
            "type": "toll"
          }
        ],
        "hd_video": false,
        "host_video": false,
        "meeting_authentication": true,
        "on_demand": false,
        "panelists_video": true,
        "post_webinar_survey": false,
        "practice_session": false,
        "question_answer": true,
        "registrants_confirmation_email": true,
        "registrants_email_notification": true,
        "registrants_restrict_number": 0,
        "registration_type": 1,
        "show_share_button": true
      },
      "start_time": "2020-02-29T18:00:00Z",
      "start_url": "https://zoomVobWJRMiZXhw.6rbaPZihxtSahkBge9lcRcAsAV8T34ZvEfy2IymiZRo",
      "timezone": "America/Los_Angeles",
      "topic": "Mark's test #2",
      "type": 5,
      "uuid": "6YdIxCiqSHy3+gs06iPesw=="
    }.to_json
  end

  def self.get_host(host_id)
    {
      "account_id": "scvbcvbcvbcvbcvbcvsdhgbsdf",
      "created_at": "2019-12-16T16:43:31Z",
      "dept": "",
      "email": "mark.vanlandingham@discourse.org",
      "first_name": "Mark",
      "group_ids": [
        "ncvbm,cvxnb"
      ],
      "host_key": "dkfjnbvdxfkjbvvdsf",
      "id": "dkfhjvbsdk,fv",
      "im_group_ids": [],
      "jid": "bwxa@xmpp.zoom.us",
      "job_title": "",
      "language": "",
      "last_login_time": "2020-01-16T20:23:28Z",
      "last_name": "VanLandingham",
      "location": "",
      "personal_meeting_url": "https://zoasgd",
      "phone_country": "",
      "phone_number": "",
      "pic_url": "https://lh3.googfg.com",
      "pmi": 480,
      "role_name": "Developer",
      "status": "active",
      "timezone": "",
      "type": 2,
      "use_pmi": false,
      "verified": 0
    }.to_json
  end
end
