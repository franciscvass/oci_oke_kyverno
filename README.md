# orm-stack-oke-helm-deployment

## Getting started

This stack will deploys an OKE cluster with one nodepool with one worker node to demonstrate how Kyverno works in OKE in OCI.
In addition it will deploy 2 VM's, a bastion and an operator to be ab;e to manage the cluster.
The stack will install Kyverno as well and will copy a folder (_kyverno-yaml_) to operator

## How to deploy?

The Deploy via ORM:

- Create a new stack
- Upload the TF configuration files
- Configure the variables
- Apply


# how to run de demo

- connect to the operator vm (the one that has the kyverno folder)
- make sure Kyverno resources are installed. Run the below to check

```
k get all -n kyverno
```
You should get an output like below. The pods must be in Running state. Deployments and replicas must be Ready and Available.

```
opc@o-kyverno:~/kyverno/01_validation[opc@o-kyverno 01_validation]$ k get all -n kyverno
NAME                                                 READY   STATUS    RESTARTS   AGE
pod/kyverno-admission-controller-5bcbdff469-d46xx    1/1     Running   0          19h
pod/kyverno-background-controller-7c7d4dbbc9-btpf9   1/1     Running   0          19h
pod/kyverno-cleanup-controller-745cbc6f8d-sjhnq      1/1     Running   0          19h
pod/kyverno-reports-controller-7867ffd654-4b7sw      1/1     Running   0          19h

NAME                                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/kyverno-background-controller-metrics   ClusterIP   10.96.212.125   <none>        8000/TCP   19h
service/kyverno-cleanup-controller              ClusterIP   10.96.205.173   <none>        443/TCP    19h
service/kyverno-cleanup-controller-metrics      ClusterIP   10.96.56.125    <none>        8000/TCP   19h
service/kyverno-reports-controller-metrics      ClusterIP   10.96.26.108    <none>        8000/TCP   19h
service/kyverno-svc                             ClusterIP   10.96.66.24     <none>        443/TCP    19h
service/kyverno-svc-metrics                     ClusterIP   10.96.102.138   <none>        8000/TCP   19h

NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kyverno-admission-controller    1/1     1            1           19h
deployment.apps/kyverno-background-controller   1/1     1            1           19h
deployment.apps/kyverno-cleanup-controller      1/1     1            1           19h
deployment.apps/kyverno-reports-controller      1/1     1            1           19h

NAME                                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/kyverno-admission-controller-5bcbdff469    1         1         1       19h
replicaset.apps/kyverno-background-controller-7c7d4dbbc9   1         1         1       19h
replicaset.apps/kyverno-cleanup-controller-745cbc6f8d      1         1         1       19h
replicaset.apps/kyverno-reports-controller-7867ffd654      1         1         1       19h
```
- change directory to kyverno-yaml/01_validation
- run the below to create a namespace _demo_ where we will test the policies
```
kubectl apply -f namespace.yaml 
```
- run the below to create a policy that will enforce deployments to have a number of 3 replicas and a label named _team_
```
kubectl apply -f k_depl_rules_namespace.yaml 
```
- check the policy
```
kubectl get policies -n demo
```
- you shoud see something like 
```
NAME                        ADMISSION   BACKGROUND   READY   AGE   MESSAGE
validation-for-deployment   true        true         True    35s   Ready
```
- Now we will try to create a deployment that does not has the number of desired replicas nor a label named _team_
- It will failed. Run the below:

```
kubectl apply -f depl.yaml 
```
- You will get :
```
Error from server: error when creating "depl.yaml": admission webhook "validate.kyverno.svc-fail" denied the request: 
resource Deployment/demo/nginx-deployment was blocked due to the following policies 
validation-for-deployment:
  check-for-replica: 'validation error: The replica must set to >=3. rule check-for-replica
    failed at path /spec/replicas/'
  check-for-team-label: 'validation error: The label ''team'' is required for all
    deployments. rule check-for-team-label failed at path /metadata/labels/team/'
```
- Open the _depl.yaml_ file and change the number of replicas from 2 to 3
- save the file an run again 
```
kubectl apply -f depl.yaml 
```
- It will fails again now because of missing label _team_

```
Error from server: error when creating "depl.yaml": admission webhook "validate.kyverno.svc-fail" denied the request: 
resource Deployment/demo/nginx-deployment was blocked due to the following policies 
validation-for-deployment:
  check-for-team-label: 'validation error: The label ''team'' is required for all
    deployments. rule check-for-team-label failed at path /metadata/labels/team/'
```

- Open the file agin and uncomment label team _(team: frontend)_
- save the file and run the command below:

```
kubectl apply -f depl.yaml 
```

- it should work fine now
- you may check the depl if you want

```
kubectl get deployments -n demo
```

```
k delete -f k_depl_rules_namespace.yaml 
k delete -f depl.yaml
k delete -f namespace.yaml
```


## Known Issues

If `terraform destroy` fails, manually remove the LoadBalancer resource configured for the Nginx Ingress Controller.

After `terrafrom destroy`, the block volumes corresponding to the PVCs used by the applications in the cluster won't be removed. You have to manually remove them.