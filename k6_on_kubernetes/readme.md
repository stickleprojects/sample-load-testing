# k6 on k8s

https://medium.com/neural-engineer/an-introduction-to-distributed-load-testing-with-k6-on-kubernetes-ba7fc87299c5

# startup

1. run docker desktop
2. ensure you have a cluster, 2nodes (watch out for the parallelism parameter in the deployment yaml)

# running it

step 1 - install k6-operator
in wsl: `curl https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml | kubectl apply -f -`
in powershell: `(wget https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml) -replace '\r\n','\n' | kubectl apply -f - `

step 2 - run the `runme.ps1` file to run the test and collect the logs
`.\runme.ps1`

# working example

step 1 - install k6-operator
in wsl: `curl https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml | kubectl apply -f -`
in powershell: `(wget https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml) -replace '\r\n','\n' | kubectl apply -f - `

step 2 - instal the k6 script as "k6-test" (this is referenced in the yaml)
in wsl: `kubectl create configmap k6-test --from-file=example/test.js`
in powershell: `kubectl create configmap k6-test --from-file=example/test.js`

step 3 - apply the k8s stuff
in wsl: `kubectl apply -f example/deployment.yaml`
in powershell: `kubectl apply -f example/deployment.yaml`
step 4 - look at the logs
in wsl (or powershell):
`kubectl get pods`
`kubectl logs <pod-name>`

setp 5 - check the configmap was created
in wsl: `kubectl get configmap k6-test`
in powershell: `kubectl get configmap k6-test`
