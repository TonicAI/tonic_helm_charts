## Tonic Helm Chart
This repository contains a Helm chart which can be used to install Tonic via `helm install`.

Project structure:
```
.
├── templates
      └── <All template files>
├── values.sample.yaml
└── README.md
```

## Configuration

### values.yaml
Before deploying this setup, rename [values.sample.yaml](values.sample.yaml) to `values.yaml` and configure the following values.

### Tonic license

- `tonicLicense`: This value will be provided by Tonic.

### Environment name

- `environmentName`: E.g. "my-company-name", or if deploying multiple Tonic instances, "my-company-name-dev" or "my-company-name-prod to differentiate instances.

### Application database
The connection details for the Postgres metadata/application database which holds Tonic's state (user accounts, workspaces, etc.).

``` yaml
tonicdb:
  host:
  port:
  dbName:
  user:
  password:
  sslMode:
```

### Consistency seed
This value is used to support [Consistency](https://docs.tonic.ai/app/generation/generators/consistency) functionality across data generations.

- `tonicStatisticsSeed`: Any signed 32-bit integer, i.e. between "-2147483648" and "2147483647". Wrap the values in quotes to avoid [type issues](https://helm.sh/docs/chart_best_practices/values/#make-types-clear) with values larger than 6 digits.

### Number of workers to deploy

- `numberOfWorkers`: An integer. Increase to more than 1 to deploy additional workers. Each worker can run a single job (Data Generation or Privacy Scan) at a time. Multiple workers are needed to run jobs simultaneously. This sets the number of replicas in the Tonic Worker Deployment spec.


### Log collection
Tonic never collects your sensitive data. Enabling this option securely and safely shares logs with Tonic's engineering team. We recommend that you enable this option. See: https://docs.tonic.ai/app/admin/sharing-logs-with-tonic

- `enableLogCollection`: "false" (default) or "true"


### Authorization to access Tonic application Docker images
Tonic hosts our application images on a private [quay.io](https://quay.io) repository. Authorization is required to pull the images.

- `dockerConfigAuth`: This value will be provided to you by Tonic and will allow you to authenticate against our private docker image repository.


### Version
You can set this to a specific Tonic version number if you wish to ensure you always get the same version. Otherwise you will always deploy the latest version of Tonic.

- `tonicVersion`: "latest" or a specific version tag. Tonic's tag convention is just the release number, e.g. "123". Release notes are available at [doc.tonic.ai](https://docs.tonic.ai/app/resources/release-notes).

### Tonic administrators
Refer to the [Tonic documentation on Administrators](https://docs.tonic.ai/app/admin/managing-admin-users) for more information. This is optional and can be configured in the following section of the values.yaml file.
``` yaml
tonicai:
  web_server:
    # Comma separated list of user emails that should be have the Admin role in Tonic.
    administrators: example@email.com,other@email.com
```

### Ingress
The Helm charts include default annotations for internal-facing load balancers for AWS and Azure. You can change to your preferred ingress method by modifying [tonic-web-server-service.yaml](tonic-web-server-service.yaml).

### Resource requests and limits
Each of the deployment YAML template files contains resource requests and limits. In some cases these may need to be modified for your environment.

### Other miscellaneous configuration
Other configuration items are necesary when using and to enable the following functionality. The Tonic support team will provide additional information if these apply for your use case.
- Connecting to an Oracle database as a source and destination
- Connecting to a Snowflake database as a source and destination
- Connecting to a Redshift database as a source and destination
- For Enterprise licensed users, configuring login/authentication via [Single Sign-On](https://docs.tonic.ai/app/admin/on-premise-deployment/single-sign-on)
- For enterprise licensed users, configuring a notifications email server



## Deploy
To install Tonic, execute the following commands.

Create a namespace: `kubectl create namespace <namespace_name>`
``` shell
$ kubectl create namespace my-tonic-namespace
namespace/my-tonic-namespace created
```

Deploy Tonic: `helm install <name_of_release> -n <namespace_name> <path-to-helm-chart>`
``` shell
$ helm install my-tonic-release -n my-tonic-namespace .
NAME: my-tonic-release
LAST DEPLOYED: Fri Jun 10 11:31:31 2022
NAMESPACE: my-tonic-namespace
STATUS: deployed
REVISION: 1
```


## Validate the deployment

Use `kubectl get all -n <namespace_name>` to check that the Tonic pods are running:

The deployment may take a few minutes with pods in the `ContainerCreating` status. Re-run the command to get an updated status. Once all pods have a status of `Running` and deployments show `READY` as `1/1`, Tonic should be available shortly after via browser at the URL/IP listed in the `EXTERNAL-IP` field next to the load balancer service. If you have modified the Helm chart ingress configuration, then this will vary. While not required, it's recommended to set up a more user-friendly domain routing to the Tonic web application.

``` shell
❯ kubectl get all -n my-tonic-namespace
NAME                                       READY   STATUS              RESTARTS   AGE
pod/tonic-notifications-578d8b8568-7tktx   0/1     ContainerCreating   0          3s
pod/tonic-pii-detection-7b7dc7f5fb-hjhbm   0/1     Running             0          3s
pod/tonic-pyml-service-7d99675b89-2jktq    0/1     ContainerCreating   0          3s
pod/tonic-web-server-b4b795d8-bbr6g        0/1     Running             0          3s
pod/tonic-worker-b8f87bc5c-srd6p           0/1     ContainerCreating   0          3s

NAME                          TYPE           CLUSTER-IP       EXTERNAL-IP                                                                       PORT(S)             AGE
service/tonic-notifications   ClusterIP      10.100.211.114   <none>                                                                            7000/TCP,7001/TCP   3s
service/tonic-pii-detection   ClusterIP      10.100.45.33     <none>                                                                            7687/TCP            3s
service/tonic-pyml-service    ClusterIP      10.100.202.103   <none>                                                                            7700/TCP            3s
service/tonic-web-server      LoadBalancer   10.100.105.239   <load-balancer-assigned-url>                                                      443:32479/TCP       3s
service/tonic-worker          ClusterIP      10.100.26.158    <none>                                                                            8080/TCP,4433/TCP   3s

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/tonic-notifications   0/1     1            0           3s
deployment.apps/tonic-pii-detection   0/1     1            0           3s
deployment.apps/tonic-pyml-service    0/1     1            0           3s
deployment.apps/tonic-web-server      0/1     1            0           3s
deployment.apps/tonic-worker          0/1     1            0           3s

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/tonic-notifications-578d8b8568   1         1         0       3s
replicaset.apps/tonic-pii-detection-7b7dc7f5fb   1         1         0       3s
replicaset.apps/tonic-pyml-service-7d99675b89    1         1         0       3s
replicaset.apps/tonic-web-server-b4b795d8        1         1         0       3s
replicaset.apps/tonic-worker-b8f87bc5c           1         1         0       3s
```

You can validate that Tonic has fully started up and is in a healthy state by running `kubectl logs deployment/tonic-web-server -n <namespace_name> | grep listening` and checking for the following output.

``` shell
❯ kubectl logs deployment/tonic-web-server -n my-tonic-namespace | grep listening
[2022-06-10T16:48:29+00:00 INF Microsoft.Hosting.Lifetime] Now listening on: http://0.0.0.0:80
[2022-06-10T16:48:29+00:00 INF Microsoft.Hosting.Lifetime] Now listening on: https://0.0.0.0:443
```

### If the Tonic UI does not load
1. Check that Tonic is successfully connecting to the application database.
Run `kubectl logs deployment/tonic-web-server -n <namespace_name> | grep "Failed to connect"`. If you see a `Failed to connect to db during startup.  Retrying in 5 seconds...` message like below, Tonic is not able to connect to your Postgres application database. Please verify the network path between Tonic and the database as well as the connection parameters.

``` shell
❯ kubectl logs deployment/tonic-web-server -n my-tonic-namespace | grep "Failed to connect"
[2022-06-10T16:50:40+00:00 WRN ] Failed to connect to db during startup.  Retrying in 5 seconds...
[2022-06-10T16:50:45+00:00 WRN ] Failed to connect to db during startup.  Retrying in 5 seconds...
[2022-06-10T16:50:50+00:00 WRN ] Failed to connect to db during startup.  Retrying in 5 seconds...
[2022-06-10T16:50:55+00:00 WRN ] Failed to connect to db during startup.  Retrying in 5 seconds...
```

2. If Tonic appears to be running and in a healthy state but you are unable to load the UI, verify that Tonic is reachable. Common issues may be a requirement to be on a VPN , firewall rules preventing access, or another issue with the ingress configuration used to expose your cluster to external user traffic.