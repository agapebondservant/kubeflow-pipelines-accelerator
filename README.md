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
export KUBEFLOW_PIPELINES_NAMESPACE=mlops-tools
tanzu package repository add kubeflow-pipelines --url ghcr.io/agapebondservant/kubeflow-pipelines:$KUBEFLOW_PACKAGE_VERSION -n ${KUBEFLOW_PIPELINES_NAMESPACE} --create-namespace
```

Verify that the Kubeflow Pipelines package is available for install:
```
tanzu package available list kubeflow-pipelines.tanzu.vmware.com --namespace ${KUBEFLOW_PIPELINES_NAMESPACE} 
```

Generate a values.yaml file to use for the install - update as desired:
```
other/scripts/generate-values-yaml.sh other/kubeflow-values.yaml #replace other/kubeflow-values.yaml with /path/to/your/values/yaml/file
```

* Install Package for Kubeflow Pipelines:
```
tanzu package install kubeflow-pipelines --package-name kubeflow-pipelines.tanzu.vmware.com --version $KUBEFLOW_PACKAGE_VERSION -n ${KUBEFLOW_PIPELINES_NAMESPACE} --values-file other/kubeflow-values.yaml
```

*Verify that the installation was successful:
```
tanzu package installed get kubeflow-pipelines -n${KUBEFLOW_PIPELINES_NAMESPACE}
```

With that, you should be able to access Kubeflow Pipelines at 
```
http://<KUBEFLOW_PIPELINES_FQDN>
```
To uninstall:
```
tanzu package installed delete kubeflow-pipelines --namespace ${KUBEFLOW_PIPELINES_NAMESPACE}  -y
tanzu package repository delete kubeflow-pipelines --namespace ${KUBEFLOW_PIPELINES_NAMESPACE}  -y
kubectl delete ns ${KUBEFLOW_PIPELINES_NAMESPACE}
```


### Build Carvel Package for Kubeflow Pipelines

* Set up local variables - update as appropriate. 
* (NOTE: To use GHCR, you must set up an access token in github - see [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token))
```
export PIPELINE_VERSION=1.8.5
export KUBEFLOW_PACKAGE_VERSION=0.0.1
export GITHUB_USER_NAME=your-github-user-name
export GHCR_REPO=ghcr.io/$GITHUB_USER_NAME/kubeflow:$KUBEFLOW_PACKAGE_VERSION
export KUBEFLOW_PIPELINES_FQDN=your-full-kubeflow-url
export KUBEFLOW_PIPELINES_NAMESPACE=your-kubeflow-namespace
```

* Generate the Package Repository:
```
other/scripts/package-script.sh
```

Next, on Github, ensure that the packages ghcr.io/agapebondservant/kubeflow-pipelines:${KUBEFLOW_PACKAGE_VERSION} and
ghcr.io/agapebondservant/kubeflow-pipelines-imgpkg:${KUBEFLOW_PACKAGE_VERSION} have been marked as **Public**.
See [here](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)

### Deploy a sample pipeline
* To deploy the sample pipeline code:
```
export MLFLOW_STAGE=<the-mlflow-stage> # ex. Staging
export GITHUB_USER_NAME=your-github-user-name
export GIT_REPO=github.com/${GITHUB_USER_NAME}/ml-image-processing-app-kfpipeline-driver.git
export EXPERIMENT_NAME=your-experiment-name #ex. kfp-main
export ENVIRONMENT_NAME=your-environment-name #ex. Staging
export KUBEFLOW_PIPELINES_HOST=your-full-kubeflow-pipelines-fqdn #ex. kfp.my-kubeflow.com
export USE_CACHE=nocache # if not nocache, will cache pipeline steps
python ./app/main.py
```