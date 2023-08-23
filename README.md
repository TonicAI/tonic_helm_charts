## Deploy
I've been having issues getting the Codefresh Pipeline working so I've been using the normal command at the from charts/tonic


Deploy Tonic:
``` shell
$ helm upgrade --install tonic -n tonic .
NAME: my-tonic-release
LAST DEPLOYED: Fri Jun 10 11:31:31 2022
NAMESPACE: my-tonic-namespace
STATUS: deployed
REVISION: 1
```