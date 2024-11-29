import RestAdapter from "discourse/adapters/rest";

export default class Webinar extends RestAdapter {
  basePath() {
    return "/zoom/";
  }
}
