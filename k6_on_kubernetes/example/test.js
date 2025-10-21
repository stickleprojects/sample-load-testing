import http from "k6/http";
import { check } from "k6";
export const options = {
  discardResponseBodies: true,
  summaryTrendStats: ["avg", "min", "med", "max", "p(90)", "p(95)", "p(99)"],
  scenarios: {
    s1: {
      executor: "constant-arrival-rate",
      rate: `${__ENV.rate}`,
      exec: `${__ENV.function}`,
      timeUnit: "1s",
      duration: `${__ENV.duration}`,
      maxVUs: `${__ENV.maxuv}`,
      preAllocatedVUs: `${__ENV.prevu}`,
    },
    s2: {
      executor: "constant-arrival-rate",
      rate: `${__ENV.rate}`,
      exec: `${__ENV.function}`,
      timeUnit: "1s",
      duration: `${__ENV.duration}`,
      maxVUs: `${__ENV.maxuv}`,
      preAllocatedVUs: `${__ENV.prevu}`,
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
