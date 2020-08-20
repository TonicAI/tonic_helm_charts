## Tonic Helm Chart ##

To install:
1. Copy `values.sample.yaml` to `values.yaml`
2. Modify `values.yaml` with your own values
    - If you wish to use the default Tonic docker registry, your worker nodes must be blessed with a Tonic docker login. Otherwise, please upload the Tonic images to ECR and replace the `dockerRepoBaseUrl` variable with your ECR address.
3. Execute `helm install tonic . -n tonic`