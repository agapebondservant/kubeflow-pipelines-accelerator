# Kubeflow Pipelines Accelerator
Template for building a Carvel Package/PackageRepository for installing Kubeflow Pipelines on TAP.

* Install App Accelerator: (see https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-cert-mgr-contour-fcd-install-cert-mgr.html)
```
tanzu package available list accelerator.apps.tanzu.vmware.com --namespace tap-install
tanzu package install accelerator -p accelerator.apps.tanzu.vmware.com -v 1.0.1 -n tap-install -f resources/app-accelerator-values.yaml
Verify that package is running: tanzu package installed get accelerator -n tap-install
Get the IP address for the App Accelerator API: kubectl get service -n accelerator-system
```

Publish Accelerators:
```
tanzu plugin install --local <path-to-tanzu-cli> all
tanzu acc create kubeflowpipelines --git-repository https://github.com/agapebondservant/kubeflow-pipelines-accelerator --git-branch main
```

### Install Kubeflow Pipelines on TAP
(NOTE: Must ensure that Carvel package already exists - see **Build Carvel Package for Kubeflow Pipelines**)
* Install PackageRepository for Kubeflow Pipelines:
```
export KUBEFLOW_PACKAGE_VERSION=0.0.1
tanzu package repository add kubeflow-pipelines --url ghcr.io/agapebondservant/kubeflow-pipelines:$KUBEFLOW_PACKAGE_VERSION -n mlops-tools --create-namespace
```

* Install Package for Kubeflow Pipelines:
```
tanzu package install kubeflow-pipelines --package-name kubeflow-pipelines.tanzu.vmware.com --version $KUBEFLOW_PACKAGE_VERSION -n mlops-tools
```

*Verify that the installation was successful:
```
tanzu package installed get kubeflow-pipelines -nmlops-tools
```

With that, you should be able to access Kubeflow Pipelines at 
```
http://kubeflow-pipelines.<DATA_E2E_BASE_URL>
```


### Build Carvel Package for Kubeflow Pipelines

* Set up local variables - update as appropriate. 
* (NOTE: To use GHCR, you must set up an access token in github - see [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token))
```
export PIPELINE_VERSION=1.8.5
export KUBEFLOW_PACKAGE_VERSION=0.0.1
export GITHUB_USER_NAME=your-github-user-name
export GHCR_REPO=ghcr.io/$GITHUB_USER_NAME/kubeflow:$KUBEFLOW_PACKAGE_VERSION
export DATA_E2E_BASE_URL=your-kubeflow-base-url.com
```

* Login to GHCR_REPO - enter the username and access token from above when prompted:
```
docker login ghcr.io
```

* Create directories:
```
mkdir kubeflow-pipelines && mkdir kubeflow-pipelines/.imgpkg && mkdir kubeflow-pipelines/config
mkdir package-repository && mkdir package-repository/.imgpkg && mkdir package-repository/packages && mkdir package-repository/packages/kubeflow-pipelines.tanzu.vmware.com
```

* Generate template files:
```
kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/cluster-scoped-resources?ref=$PIPELINE_VERSION" -oyaml --dry-run=client > kubeflow-pipelines/config/cluster-scoped-resources.yaml
kubectl apply -f kubeflow-pipelines/config/cluster-scoped-resources.yaml
kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/env/dev?ref=$PIPELINE_VERSION" -oyaml --dry-run=client > kubeflow-pipelines/config/install.yaml
envsubst < other/kfp-http-proxy.in.yaml > other/kfp-http-proxy.yaml
mv other/kfp-http-proxy.yaml kubeflow-pipelines/config/
kubectl delete -f kubeflow-pipelines/config/cluster-scoped-resources.yaml
```

* Lock images via **kbld**:
```
kbld -f kubeflow-pipelines/config/ --imgpkg-lock-output kubeflow-pipelines/.imgpkg/images.yml
```

* Push the locked images and templates for **kubeflow-pipelines** to the container registry:
```
imgpkg push -b ghcr.io/agapebondservant/kubeflow-pipelines-imgpkg:$KUBEFLOW_PACKAGE_VERSION -f kubeflow-pipelines/
```

* Update and copy the **package** files:
```
cp other/metadata.yaml package-repository/packages/kubeflow-pipelines.tanzu.vmware.com
cp other/0.1.0.yaml package-repository/packages/kubeflow-pipelines.tanzu.vmware.com/${KUBEFLOW_PACKAGE_VERSION}.yaml
sed -i ".bak" s/0\.1\.0/$KUBEFLOW_PACKAGE_VERSION/g package-repository/packages/kubeflow-pipelines.tanzu.vmware.com/${KUBEFLOW_PACKAGE_VERSION}.yaml
rm -f package-repository/packages/kubeflow-pipelines.tanzu.vmware.com/${KUBEFLOW_PACKAGE_VERSION}.yaml.bak
```

Lock images via **kbld***:
```
kbld -f package-repository/packages/ --imgpkg-lock-output package-repository/.imgpkg/images.yml
```

Push the locked images and templates for the **kubeflow-pipelines** package to the container registry:
```
imgpkg push -b ghcr.io/agapebondservant/kubeflow-pipelines:${KUBEFLOW_PACKAGE_VERSION} -f package-repository/
```

Next, on Github, ensure that the packages ghcr.io/agapebondservant/kubeflow-pipelines:${KUBEFLOW_PACKAGE_VERSION} and
ghcr.io/agapebondservant/kubeflow-pipelines-imgpkg:${KUBEFLOW_PACKAGE_VERSION} have been marked as **Public**.
See [here](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)