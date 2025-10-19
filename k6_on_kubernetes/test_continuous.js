import http from "k6/http";
import { check } from "k6";
export const options = {
  discardResponseBodies: true,
  summaryTrendStats: ["avg", "min", "med", "max", "p(90)", "p(95)", "p(99)"],
  scenarios: {
    s1: {
      executor: "externally-controlled",

      exec: `${__ENV.function}`,
      vus: 10,
      maxVUs: 50,

      duration: "10m",
    },
    s2: {
      executor: "externally-controlled",

      exec: `${__ENV.function}`,
      vus: 10,
      maxVUs: 50,

      duration: "10m",
    },
  },
};
export function handleSummary(data) {
  return {
    stdout: JSON.stringify(data),
  };
}
export function function1() {
  const res = http.get("https://test-api.k6.io/public/crocodiles/");
  check(res, { "status was 200": (r) => r.status === 200 });
}
