import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import WebinarRegister from "discourse/plugins/discourse-zoom/discourse/components/webinar-register";

module("Integration | Component | webinar-register", function (hooks) {
  setupRenderingTest(hooks);

  test("Google Calendar link", async function (assert) {
    const self = this;

    const webinar = {
      id: 99,
      title: "Spider Webinar",
      status: "scheduled",
      ends_at: "2031-09-01T12:00:00Z",
      starts_at: "2031-09-01T11:00:00Z",
      attendees: [{ id: 1 }],
      panelists: [{ id: 1 }],
      host: { id: 101 },
      join_url: "https://zoom.us/j/123456789",
    };
    this.set("webinar", webinar);
    this.currentUser.id = 101;

    await render(
      <template>
        <WebinarRegister
          @webinar={{self.webinar}}
          @showCalendarButtons={{true}}
        />
      </template>
    );
    assert
      .dom(".zoom-add-to-calendar-container a")
      .hasAttribute(
        "href",
        "http://www.google.com/calendar/event?action=TEMPLATE&text=Spider%20Webinar&dates=20310901T110000Z/20310901T120000Z&details=Join%20from%20a%20PC%2C%20Mac%2C%20iPad%2C%20iPhone%20or%20Android%20device%3A%0A%20%20%20%20Please%20click%20this%20URL%20to%20join.%20%3Ca%20href%3D%22https%3A%2F%2Fzoom.us%2Fj%2F123456789%22%3Ehttps%3A%2F%2Fzoom.us%2Fj%2F123456789%3C%2Fa%3E&location=https%3A%2F%2Fzoom.us%2Fj%2F123456789"
      );
  });
});
