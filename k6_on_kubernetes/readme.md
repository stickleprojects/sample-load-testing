# k6 on k8s

https://medium.com/neural-engineer/an-introduction-to-distributed-load-testing-with-k6-on-kubernetes-ba7fc87299c5

# setup

step 1 - install k6-operator
in wsl: `curl https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml | kubectl apply -f -`

step 2 - run the `runme.ps1` file to run the test and collect the logs
`.\runme.ps1`
