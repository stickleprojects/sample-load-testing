import http from "k6/http";
import { check, sleep, group } from "k6";

export const options = {
  stages: [
    { duration: "30s", target: 20 },
    { duration: "1m30s", target: 10 },
    { duration: "20s", target: 0 },
  ],
};

export default function () {
  group("testing root", function () {
    const res = http.get("http://switchApi:8080/");
    check(res, { "status was 200": (r) => r.status == 200 });
    sleep(1);
  });
  group("testing weatherforecast", function () {
    const res2 = http.get("http://switchApi:8080/weatherforecast");
    check(res2, { "status was 200": (r) => r.status == 200 });
    sleep(1);
  });
}
