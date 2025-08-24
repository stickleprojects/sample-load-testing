# Sample Load Testing

This example application hosts the following services:

| _Service_  | Port                  | _Notes_                                                   |
| ---------- | --------------------- | --------------------------------------------------------- |
| Grafana    | http://localhost:3111 | Dashboards and charts (admin:admin)                       |
| pg_grafana |                       | Postgres to hold grafana configuration                    |
| Prometheus | http://localhost:9090 | Prometheus sink for the sample aplicaiton metrics         |
| switchApi  | http://localhost:9000 | Simple .netcore webapi to react to the load test          |
| influxdb   |                       | Database to hold k6 results                               |
| k6         |                       | K6 load test host, running the tests from k6scripts/\*.js |

On startup the grafana main_dashboard will be created pointing to prometheus with a sample request duration per route from the switchApi

# Datasources imported into grafana

- InfluxDb
- Prometheus

# Dashboards created by default

| Dashboard          | Notes                                                                        |
| ------------------ | ---------------------------------------------------------------------------- |
| local perf testing | contains the default grafs (starts with avg response time for all endpoints) |

# Useful folders

| Folder               | notes                                                     | external refs                                                 |
| -------------------- | --------------------------------------------------------- | ------------------------------------------------------------- |
| grafana/provisioning | grafana startup, add more dashboards and datasources here | https://community.grafana.com/t/data-source-on-startup/8618/2 |
| k6scripts            | add more k6 test scripts here                             | https://grafana.com/docs/k6/latest/get-started/running-k6/    |

# FAQ

## How do i add more tests

Add more tests by editing `k6scripts/test1.js`
If you want to add more JS files, you will need to edit the `docker-compose.yaml` script, since they are mentioned in there
