# Login to GHCR_REPO - enter the username and access token from above when prompted:
docker login ghcr.io

# Create directories:
rm -rf kubeflow-pipelines && rm -rf package-repository
mkdir kubeflow-pipelines && mkdir kubeflow-pipelines/.imgpkg && mkdir kubeflow-pipelines/config
mkdir package-repository && mkdir package-repository/.imgpkg && mkdir package-repository/packages && mkdir package-repository/packages/kubeflow-pipelines.tanzu.vmware.com

# Generate template files:
kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/cluster-scoped-resources?ref=$PIPELINE_VERSION" -oyaml --dry-run=client > kubeflow-pipelines/config/cluster-scoped-resources.yaml
kubectl apply -f kubeflow-pipelines/config/cluster-scoped-resources.yaml
kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/env/dev?ref=$PIPELINE_VERSION" -oyaml --dry-run=client > kubeflow-pipelines/config/install.yaml
cp other/kfp-http-proxy.yaml kubeflow-pipelines/config/
cp other/kubeflow-values-schema.yaml kubeflow-pipelines/config/

# Lock images via **kbld**:
kbld -f kubeflow-pipelines/config/ --imgpkg-lock-output kubeflow-pipelines/.imgpkg/images.yml

# Push the locked images and templates for **kubeflow-pipelines** to the container registry:
imgpkg push -b ghcr.io/agapebondservant/kubeflow-pipelines-imgpkg:$KUBEFLOW_PACKAGE_VERSION -f kubeflow-pipelines/

# Update and copy the **package** files:
cp other/metadata.yaml package-repository/packages/kubeflow-pipelines.tanzu.vmware.com
ytt -f kubeflow-pipelines/config/kubeflow-values-schema.yaml --data-values-schema-inspect -o openapi-v3 > other/schema-openapi.yaml
ytt -f other/kubeflow-package-template.yaml  --data-value-file openapi=other/schema-openapi.yaml -v version="${KUBEFLOW_PACKAGE_VERSION}" > package-repository/packages/kubeflow-pipelines.tanzu.vmware.com/${KUBEFLOW_PACKAGE_VERSION}.yaml

# Lock images via **kbld***:
kbld -f package-repository/packages/ --imgpkg-lock-output package-repository/.imgpkg/images.yml


# Push the locked images and templates for the **kubeflow-pipelines** package to the container registry:
imgpkg push -b ghcr.io/agapebondservant/kubeflow-pipelines:${KUBEFLOW_PACKAGE_VERSION} -f package-repository/