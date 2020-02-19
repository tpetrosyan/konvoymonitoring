# konvoymonitoring

Installs [prometheus-operator](https://github.com/coreos/prometheus-operator) to create/configure/manage Prometheus clusters atop Kubernetes. This chart includes multiple components and is suitable for a variety of use-cases.
Installs [Thanos](https://github.com/improbable-eng/thanos) solution. To understand how Thanos works please read it's official [Architecture design](https://github.com/improbable-eng/thanos/blob/master/docs/design.md)

The default installation is intended to suit monitoring a kubernetes cluster the chart is deployed onto. It closely matches the kube-prometheus project.
- [prometheus-operator](https://github.com/coreos/prometheus-operator)
- [prometheus](https://prometheus.io/)
- [alertmanager](https://prometheus.io/)
- [node-exporter](https://github.com/helm/charts/tree/master/stable/prometheus-node-exporter)
- [kube-state-metrics](https://github.com/helm/charts/tree/master/stable/kube-state-metrics)
- [grafana](https://github.com/helm/charts/tree/master/stable/grafana)
- [thanos](https://thanos.io/getting-started.md/)
- service monitors to scrape internal kubernetes components
  - kube-apiserver
  - kube-scheduler
  - kube-controller-manager
  - etcd
  - kube-dns/coredns
  - kube-proxy

With the installation, the chart also includes dashboards and alerts.

The same chart can be used to run multiple prometheus instances in the same cluster if required. To achieve this, the other components need to be disabled - it is necessary to run only one instance of prometheus-operator and a pair of alertmanager pods for an HA configuration.

## TL;DR;

```console
$ helm install stable/prometheus-operator
```

## Introduction

This chart bootstraps a [prometheus-operator](https://github.com/coreos/prometheus-operator) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.  The chart can be installed multiple times to create separate Prometheus instances managed by Prometheus Operator.

## Prerequisites
  - Kubernetes 1.10+ with Beta APIs
  - Helm 2.12+ (If using Helm < 2.14, [see below for CRD workaround](#Helm-fails-to-create-CRDs))

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release stable/prometheus-operator
```

The command deploys prometheus-operator on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

The default installation includes Prometheus Operator, Alertmanager, Grafana, and configuration for scraping Kubernetes infrastructure.

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

CRDs created by this chart are not removed by default and should be manually cleaned up:

```console
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
```

## Work-Arounds for Known Issues

### Running on private GKE clusters
When Google configure the control plane for private clusters, they automatically configure VPC peering between your Kubernetes cluster’s network and a separate Google managed project. In order to restrict what Google are able to access within your cluster, the firewall rules configured restrict access to your Kubernetes pods. This means that in order to use the webhook component with a GKE private cluster, you must configure an additional firewall rule to allow the GKE control plane access to your webhook pod.

You can read more information on how to add firewall rules for the GKE control plane nodes in the [GKE docs](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#add_firewall_rules)

Alternatively, you can disable the hooks by setting `prometheusOperator.admissionWebhooks.enabled=false`.

### Helm fails to create CRDs
You should upgrade to Helm 2.14 + in order to avoid this issue. However, if you are stuck with an earlier Helm release you should instead use the following approach: Due to a bug in helm, it is possible for the 5 CRDs that are created by this chart to fail to get fully deployed before Helm attempts to create resources that require them. This affects all versions of Helm with a [potential fix pending](https://github.com/helm/helm/pull/5112). In order to work around this issue when installing the chart you will need to make sure all 5 CRDs exist in the cluster first and disable their previsioning by the chart:

1. Create CRDs
```console
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/podmonitor.crd.yaml
```

2. Wait for CRDs to be created, which should only take a few seconds

3. Install the chart, but disable the CRD provisioning by setting `prometheusOperator.createCustomResource=false`
```console
$ helm install --name my-release stable/prometheus-operator --set prometheusOperator.createCustomResource=false
```

## Upgrading an existing Release to a new major version

A major chart version change (like v1.2.3 -> v2.0.0) indicates that there is an
incompatible breaking change needing manual actions.

### Upgrading from 7.x.x to 8.x.x
Due to new template functions being used in the rules in version 8.x.x of the chart, an upgrade to Prometheus Operator and Prometheus is necessary in order to support them.
First, upgrade to the latest version of 7.x.x
```sh
helm upgrade <your-release-name> stable/prometheus-operator --version 7.4.0
```
Then upgrade to 8.x.x
```sh
helm upgrade <your-release-name> stable/prometheus-operator
```
Minimal recommended Prometheus version for this chart release is `2.12.x`

### Upgrading from 6.x.x to 7.x.x
Due to a change in grafana subchart, version 7.x.x now requires Helm >= 2.12.0.

### Upgrading from 5.x.x to 6.x.x
Due to a change in deployment labels of kube-state-metrics, the upgrade requires `helm upgrade --force` in order to re-create the deployment. If this is not done an error will occur indicating that the deployment cannot be modified:

```
invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/name":"kube-state-metrics"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable
```
If this error has already been encountered, a `helm history` command can be used to determine which release has worked, then `helm rollback` to the release, then `helm upgrade --force` to this new one

## prometheus.io/scrape
The prometheus operator does not support annotation-based discovery of services, using the `serviceMonitor` CRD in its place as it provides far more configuration options. For information on how to use servicemonitors, please see the documentation on the coreos/prometheus-operator documentation here: [Running Exporters](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/running-exporters.md)

## Configuration

The following tables list the configurable parameters of the prometheus-operator chart and their default values.

### General
| Parameter | Description | Default |
| ----- | ----------- | ------ |
| `additionalPrometheusRulesMap` | Map of `prometheusRule` objects to create with the key used as the name of the rule spec. If defined, this will take precedence over `additionalPrometheusRules`. See https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusrulespec. | `nil` |
| `additionalPrometheusRules` | *DEPRECATED* Will be removed in a future release.  Please use **additionalPrometheusRulesMap** instead.  List of `prometheusRule` objects to create. See https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#prometheusrulespec. | `[]` |
| `commonLabels` | Labels to apply to all resources | `[]` |
| `defaultRules.annotations` | Annotations for default rules for monitoring the cluster | `{}` |
| `defaultRules.create` | Create default rules for monitoring the cluster | `true` |
| `defaultRules.labels` | Labels for default rules for monitoring the cluster | `{}` |
| `defaultRules.rules.PrometheusOperator` | Create Prometheus Operator  default rules| `true` |
| `defaultRules.rules.alertmanager` | Create default rules for Alert Manager | `true` |
| `defaultRules.rules.etcd` | Create default rules for ETCD | `true` |
| `defaultRules.rules.general` | Create General default rules| `true` |
| `defaultRules.rules.k8s` | Create K8S default rules| `true` |
| `defaultRules.rules.kubeApiserver` | Create Api Server default rules| `true` |
| `defaultRules.rules.kubePrometheusNodeAlerting` | Create Node Alerting default rules| `true` |
| `defaultRules.rules.kubePrometheusNodeRecording` | Create Node Recording default rules| `true` |
| `defaultRules.rules.kubeScheduler` | Create Kubernetes Scheduler default rules| `true` |
| `defaultRules.rules.kubernetesAbsent` | Create Kubernetes Absent (example API Server down) default rules| `true` |
| `defaultRules.rules.kubernetesApps` | Create Kubernetes Apps  default rules| `true` |
| `defaultRules.rules.kubernetesResources` | Create Kubernetes Resources  default rules| `true` |
| `defaultRules.rules.kubernetesStorage` | Create Kubernetes Storage  default rules| `true` |
| `defaultRules.rules.kubernetesSystem` | Create Kubernetes System  default rules| `true` |
| `defaultRules.rules.network` | Create networking default rules | `true` |
| `defaultRules.rules.node` | Create Node default rules | `true` |
| `defaultRules.rules.prometheus` | Create Prometheus  default rules| `true` |
| `defaultRules.rules.time` | Create time default rules | `true` |
| `fullnameOverride` | Provide a name to substitute for the full names of resources |`""`|
| `global.imagePullSecrets` | Reference to one or more secrets to be used when pulling images | `[]` |
| `global.rbac.create` | Create RBAC resources | `true` |
| `global.rbac.pspEnabled` | Create pod security policy resources | `true` |
| `kubeTargetVersionOverride` | Provide a target gitVersion of K8S, in case .Capabilites.KubeVersion is not available (e.g. `helm template`) |`""`|
| `nameOverride` | Provide a name in place of `prometheus-operator` |`""`|

### Prometheus Operator
| Parameter | Description | Default |
| ----- | ----------- | ------ |
| `prometheusOperator.admissionWebhooks.enabled` | Create PrometheusRules admission webhooks. Mutating webhook will patch PrometheusRules objects indicating they were validated. Validating webhook will check the rules syntax. | `true` |
| `prometheusOperator.admissionWebhooks.failurePolicy` | Failure policy for admission webhooks | `Fail` |
| `prometheusOperator.admissionWebhooks.patch.enabled` | If true, will use a pre and post install hooks to generate a CA and certificate to use for the prometheus operator tls proxy, and patch the created webhooks with the CA. | `true` |
| `prometheusOperator.admissionWebhooks.patch.image.pullPolicy` | Image pull policy for the webhook integration jobs | `IfNotPresent` |
| `prometheusOperator.admissionWebhooks.patch.image.repository` | Repository to use for the webhook integration jobs | `jettech/kube-webhook-certgen` |
| `prometheusOperator.admissionWebhooks.patch.image.tag` | Tag to use for the webhook integration jobs | `v1.0.0` |
| `prometheusOperator.admissionWebhooks.patch.resources` | Resource limits for admission webhook | `{}` |
| `prometheusOperator.admissionWebhooks.patch.nodeSelector` | Node selector for running admission hook patch jobs | `nil` |
| `prometheusOperator.admissionWebhooks.patch.podAnnotations` | Annotations for the webhook job pods | `nil` |
| `prometheusOperator.admissionWebhooks.patch.priorityClassName` | Priority class for the webhook integration jobs | `nil` |
| `prometheusOperator.affinity` | Assign custom affinity rules to the prometheus operator https://kubernetes.io/docs/concepts/configuration/assign-pod-node/ | `{}` |
| `prometheusOperator.cleanupCustomResource` | Attempt to delete CRDs when the release is removed. This option may be useful while testing but is not recommended, as deleting the CRD definition will delete resources and prevent the operator from being able to clean up resources that it manages | `false` |
| `prometheusOperator.configReloaderCpu` | Set the prometheus config reloader side-car CPU limit. If unset, uses the prometheus-operator project default | `nil` |
| `prometheusOperator.configReloaderMemory` | Set the prometheus config reloader side-car memory limit. If unset, uses the prometheus-operator project default | `nil` |
| `prometheusOperator.configmapReloadImage.repository` | Repository for configmapReload image | `quay.io/coreos/configmap-reload` |
| `prometheusOperator.configmapReloadImage.tag` | Tag for configmapReload image | `v0.0.1` |
| `prometheusOperator.createCustomResource` | Create CRDs. Required if deploying anything besides the operator itself as part of the release. The operator will create / update these on startup. If your Helm version < 2.10 you will have to either create the CRDs first or deploy the operator first, then the rest of the resources. Regardless of value of this, Helm v3+ will install the CRDs if those are not present already. Use `--skip-crds` with `helm install` if you want to skip CRD creation | `true` |
| `prometheusOperator.namespaces` |  Namespaces to scope the interaction of the Prometheus Operator and the apiserver (allow list). This is mutually exclusive with `denyNamespaces`. Setting this to an empty object will disable the configuration | `{}` |
| `prometheusOperator.namespaces.releaseNamespace` | Include the release namespace | `false` |
| `prometheusOperator.namespaces.additional` | Include additional namespaces besides the release namespace | `[]` |
| `prometheusOperator.denyNamespaces` | Namespaces not to scope the interaction of the Prometheus Operator (deny list). This is mutually exclusive with `namespaces` | `[]` |
| `prometheusOperator.enabled` | Deploy Prometheus Operator. Only one of these should be deployed into the cluster | `true` |
| `prometheusOperator.hyperkubeImage.repository` | Image pull policy for hyperkube image used to perform maintenance tasks | `IfNotPresent` |
| `prometheusOperator.hyperkubeImage.repository` | Repository for hyperkube image used to perform maintenance tasks | `k8s.gcr.io/hyperkube` |
| `prometheusOperator.hyperkubeImage.tag` | Tag for hyperkube image used to perform maintenance tasks | `v1.12.1` |
| `prometheusOperator.image.pullPolicy` | Pull policy for prometheus operator image | `IfNotPresent` |
| `prometheusOperator.image.repository` | Repository for prometheus operator image | `quay.io/coreos/prometheus-operator` |
| `prometheusOperator.image.tag` | Tag for prometheus operator image | `v0.33.0` |
| `prometheusOperator.kubeletService.enabled` | If true, the operator will create and maintain a service for scraping kubelets | `true` |
| `prometheusOperator.kubeletService.namespace` | Namespace to deploy kubelet service | `kube-system` |
| `prometheusOperator.logFormat` | Operator log output formatting | `"logfmt"` |
| `prometheusOperator.logLevel` | Operator log level. Possible values: "all", "debug",	"info",	"warn",	"error", "none" | `"info"` |
| `prometheusOperator.nodeSelector` | Prometheus operator node selector https://kubernetes.io/docs/user-guide/node-selection/ | `{}` |
| `prometheusOperator.podAnnotations` | Annotations to add to the operator pod | `{}` |
| `prometheusOperator.podLabels` | Labels to add to the operator pod | `{}` |
| `prometheusOperator.priorityClassName` | Name of Priority Class to assign pods | `nil` |
| `prometheusOperator.prometheusConfigReloaderImage.repository` | Repository for config-reloader image | `quay.io/coreos/prometheus-config-reloader` |
| `prometheusOperator.prometheusConfigReloaderImage.tag` | Tag for config-reloader image | `v0.33.0` |
| `prometheusOperator.resources` | Resource limits for prometheus operator | `{}` |
| `prometheusOperator.securityContext` | SecurityContext for prometheus operator | `{"runAsNonRoot": true, "runAsUser": 65534}` |
| `prometheusOperator.service.annotations` | Annotations to be added to the prometheus operator service | `{}` |
| `prometheusOperator.service.clusterIP` | Prometheus operator service clusterIP IP | `""` |
| `prometheusOperator.service.externalIPs` | List of IP addresses at which the Prometheus Operator server service is available | `[]` |
| `prometheusOperator.service.labels` |  Prometheus Operator Service Labels | `{}` |
| `prometheusOperator.service.loadBalancerIP` |  Prometheus Operator Loadbalancer IP | `""` |
| `prometheusOperator.service.loadBalancerSourceRanges` | Prometheus Operator Load Balancer Source Ranges | `[]` |
| `prometheusOperator.service.nodePortTls` | TLS port to expose prometheus operator service on each node | `30443` |
| `prometheusOperator.service.nodePort` | Port to expose prometheus operator service on each node | `30080` |
| `prometheusOperator.service.type` | Prometheus operator service type | `ClusterIP` |
| `prometheusOperator.serviceAccount.create` | Create a serviceaccount for the operator | `true` |
| `prometheusOperator.serviceAccount.name` | Operator serviceAccount name | `""` |
| `prometheusOperator.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `prometheusOperator.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping the operator instance. | `` |
| `prometheusOperator.serviceMonitor.relabelings` | The `relabel_configs` for scraping the operator instance. | `` |
| `prometheusOperator.serviceMonitor.selfMonitor` | Enable monitoring of prometheus operator | `true` |
| `prometheusOperator.tlsProxy.enabled` | Enable a TLS proxy container. Only the `squareup/ghostunnel` command line arguments are currently supported and the secret where the cert is loaded from is expected to be provided by the admission webhook | `true` |
| `prometheusOperator.tlsProxy.image.repository` | Repository for the TLS proxy container | `squareup/ghostunnel` |
| `prometheusOperator.tlsProxy.image.tag` | Repository for the TLS proxy container | `v1.4.1` |
| `prometheusOperator.tlsProxy.image.pullPolicy` | Image pull policy for the TLS proxy container | `IfNotPresent` |
| `prometheusOperator.tlsProxy.resources` | Resource requests and limits for the TLS proxy container | `{}` |
| `prometheusOperator.tolerations` | Tolerations for use with node taints https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ | `[]` |


### Prometheus
| Parameter | Description | Default |
| ----- | ----------- | ------ |
| `prometheus.additionalServiceMonitors` | List of `ServiceMonitor` objects to create. See https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#servicemonitorspec | `[]` |
| `prometheus.enabled` | Deploy prometheus | `true` |
| `prometheus.annotations` | Prometheus annotations | `{}` |
| `prometheus.ingress.annotations` | Prometheus Ingress annotations | `{}` |
| `prometheus.ingress.enabled` | If true, Prometheus Ingress will be created | `false` |
| `prometheus.ingress.hosts` | Prometheus Ingress hostnames | `[]` |
| `prometheus.ingress.labels` | Prometheus Ingress additional labels | `{}` |
| `prometheus.ingress.paths` | Prometheus Ingress paths | `[]` |
| `prometheus.ingress.tls` | Prometheus Ingress TLS configuration (YAML) | `[]` |
| `prometheus.ingressPerReplica.annotations` | Prometheus pre replica Ingress annotations | `{}` |
| `prometheus.ingressPerReplica.enabled` | If true, create an Ingress for each Prometheus server replica in the StatefulSet | `false` |
| `prometheus.ingressPerReplica.hostPrefix` |  | `""` |
| `prometheus.ingressPerReplica.hostDomain` |  | `""` |
| `prometheus.ingressPerReplica.labels` | Prometheus per replica Ingress additional labels | `{}` |
| `prometheus.ingressPerReplica.paths` | Prometheus per replica Ingress paths | `[]` |
| `prometheus.ingressPerReplica.tlsSecretName` | Secret name containing the TLS certificate for Prometheus per replica ingress | `[]` |
| `prometheus.podDisruptionBudget.enabled` | If true, create a pod disruption budget for prometheus pods. The created resource cannot be modified once created - it must be deleted to perform a change | `false` |
| `prometheus.podDisruptionBudget.maxUnavailable` | Maximum number / percentage of pods that may be made unavailable | `""` |
| `prometheus.podDisruptionBudget.minAvailable` | Minimum number / percentage of pods that should remain scheduled | `1` |
| `prometheus.podSecurityPolicy.allowedCapabilities` | Prometheus Pod Security Policy allowed capabilities | `""` |
| `prometheus.prometheusSpec.additionalAlertManagerConfigs` | AdditionalAlertManagerConfigs allows for manual configuration of alertmanager jobs in the form as specified in the official Prometheus documentation: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<alertmanager_config>. AlertManager configurations specified are appended to the configurations generated by the Prometheus Operator. As AlertManager configs are appended, the user is responsible to make sure it is valid. Note that using this feature may expose the possibility to break upgrades of Prometheus. It is advised to review Prometheus release notes to ensure that no incompatible AlertManager configs are going to break Prometheus after the upgrade. | `{}` |
| `prometheus.prometheusSpec.additionalAlertRelabelConfigs` | AdditionalAlertRelabelConfigs allows specifying additional Prometheus alert relabel configurations. Alert relabel configurations specified are appended to the configurations generated by the Prometheus Operator. Alert relabel configurations specified must have the form as specified in the official Prometheus documentation: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#alert_relabel_configs. As alert relabel configs are appended, the user is responsible to make sure it is valid. Note that using this feature may expose the possibility to break upgrades of Prometheus. It is advised to review Prometheus release notes to ensure that no incompatible alert relabel configs are going to break Prometheus after the upgrade. | `[]` |
| `prometheus.prometheusSpec.additionalScrapeConfigsExternal` | Enable additional scrape configs that are managed externally to this chart. This option requires a secret in the same namespace as Prometheus with the name, `prometheus-operator-prometheus-scrape-confg` and a key of `additional-scrape-configs.yaml`. Note that the prometheus will fail to provision if the correct secret does not exist. | `false` |
| `prometheus.prometheusSpec.additionalScrapeConfigs` | AdditionalScrapeConfigs allows specifying additional Prometheus scrape configurations. Scrape configurations are appended to the configurations generated by the Prometheus Operator. Job configurations must have the form as specified in the official Prometheus documentation: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<scrape_config>. As scrape configs are appended, the user is responsible to make sure it is valid. Note that using this feature may expose the possibility to break upgrades of Prometheus. It is advised to review Prometheus release notes to ensure that no incompatible scrape configs are going to break Prometheus after the upgrade. | `{}` |
| `prometheus.prometheusSpec.affinity` | Assign custom affinity rules to the prometheus instance https://kubernetes.io/docs/concepts/configuration/assign-pod-node/ | `{}` |
| `prometheus.prometheusSpec.alertingEndpoints` | Alertmanagers to which alerts will be sent https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#alertmanagerendpoints Default configuration will connect to the alertmanager deployed as part of this release | `[]` |
| `prometheus.prometheusSpec.configMaps` | ConfigMaps is a list of ConfigMaps in the same namespace as the Prometheus object, which shall be mounted into the Prometheus Pods. The ConfigMaps are mounted into /etc/prometheus/configmaps/ | `[]` |
| `prometheus.prometheusSpec.containers` | Containers allows injecting additional containers. This is meant to allow adding an authentication proxy to a Prometheus pod. |`[]`|
| `prometheus.prometheusSpec.enableAdminAPI` | EnableAdminAPI enables Prometheus the administrative HTTP API which includes functionality such as deleting time series. | `false` |
| `prometheus.prometheusSpec.evaluationInterval` | Interval between consecutive evaluations. | `""` |
| `prometheus.prometheusSpec.externalLabels` | The labels to add to any time series or alerts when communicating with external systems (federation, remote storage, Alertmanager). | `{}` |
| `prometheus.prometheusSpec.externalUrl` | The external URL the Prometheus instances will be available under. This is necessary to generate correct URLs. This is necessary if Prometheus is not served from root of a DNS name. | `""` |
| `prometheus.prometheusSpec.image.repository` | Base image to use for a Prometheus deployment. | `quay.io/prometheus/prometheus` |
| `prometheus.prometheusSpec.image.tag` | Tag of Prometheus container image to be deployed. | `v2.12.0` |
| `prometheus.prometheusSpec.listenLocal` | ListenLocal makes the Prometheus server listen on loopback, so that it does not bind against the Pod IP. | `false` |
| `prometheus.prometheusSpec.logFormat` | Log format for Prometheus to be configured with. | `logfmt` |
| `prometheus.prometheusSpec.logLevel` | Log level for Prometheus to be configured with. | `info` |
| `prometheus.prometheusSpec.nodeSelector` | Define which Nodes the Pods are scheduled on. | `{}` |
| `prometheus.prometheusSpec.paused` | When a Prometheus deployment is paused, no actions except for deletion will be performed on the underlying objects. | `false` |
| `prometheus.prometheusSpec.podAntiAffinityTopologyKey` | If anti-affinity is enabled sets the topologyKey to use for anti-affinity. This can be changed to, for example `failure-domain.beta.kubernetes.io/zone`| `kubernetes.io/hostname` |
| `prometheus.prometheusSpec.podAntiAffinity` | Pod anti-affinity can prevent the scheduler from placing Prometheus replicas on the same node. The default value "soft" means that the scheduler should *prefer* to not schedule two replica pods onto the same node but no guarantee is provided. The value "hard" means that the scheduler is *required* to not schedule two replica pods onto the same node. The value "" will disable pod anti-affinity so that no anti-affinity rules will be configured. | `""` |
| `prometheus.prometheusSpec.podMetadata` | Standard object’s metadata. More info: https://github.com/kubernetes/community/blob/master/contributors/devel/api-conventions.md#metadata Metadata Labels and Annotations gets propagated to the prometheus pods. | `{}` |
| `prometheus.prometheusSpec.priorityClassName` | Priority class assigned to the Pods | `""` |
| `prometheus.prometheusSpec.prometheusExternalLabelNameClear` | If true, the Operator won't add the external label used to denote Prometheus instance name. | `false` |
| `prometheus.prometheusSpec.prometheusExternalLabelName` | Name of the external label used to denote Prometheus instance name. | `""` |
| `prometheus.prometheusSpec.query` | QuerySpec defines the query command line flags when starting Prometheus. Not all parameters are supported by the operator - [see coreos documentation](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#queryspec) | `{}` |
| `prometheus.prometheusSpec.remoteRead` | If specified, the remote_read spec. This is an experimental feature, it may change in any upcoming release in a breaking way. | `[]` |
| `prometheus.prometheusSpec.remoteWrite` | If specified, the remote_write spec. This is an experimental feature, it may change in any upcoming release in a breaking way. | `[]` |
| `prometheus.prometheusSpec.remoteWriteDashboards` | Enable/Disable Grafana dashboards provisioning for prometheus remote write feature | `false` |
| `prometheus.prometheusSpec.replicaExternalLabelNameClear` | If true, the Operator won't add the external label used to denote replica name. | `false` |
| `prometheus.prometheusSpec.replicaExternalLabelName` | Name of the external label used to denote replica name. | `""` |
| `prometheus.prometheusSpec.replicas` | Number of instances to deploy for a Prometheus deployment. | `1` |
| `prometheus.prometheusSpec.resources` | Define resources requests and limits for single Pods. | `{}` |
| `prometheus.prometheusSpec.retentionSize` | Used Storage Prometheus shall retain data for. Example 50GiB (50 Gigabyte). Can be combined with prometheus.prometheusSpec.retention | `""` |
| `prometheus.prometheusSpec.walCompression` | Enable compression of the write-ahead log using Snappy. This flag is only available in versions of Prometheus >= 2.11.0. | `false` |
| `prometheus.prometheusSpec.retention` | Time duration Prometheus shall retain data for. Must match the regular expression `[0-9]+(ms\|s\|m\|h\|d\|w\|y)` (milliseconds seconds minutes hours days weeks years). | `10d` |
| `prometheus.prometheusSpec.routePrefix` | The route prefix Prometheus registers HTTP handlers for. This is useful, if using ExternalURL and a proxy is rewriting HTTP routes of a request, and the actual ExternalURL is still true, but the server serves requests under a different route prefix. For example for use with `kubectl proxy`. | `/` |
| `prometheus.prometheusSpec.ruleNamespaceSelector` | Namespaces to be selected for PrometheusRules discovery. If nil, select own namespace. See [namespaceSelector](https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#namespaceselector) for usage | `{}` |
| `prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues` | If true, a nil or {} value for prometheus.prometheusSpec.ruleSelector will cause the prometheus resource to be created with selectors based on values in the helm deployment, which will also match the PrometheusRule resources created. | `true` |
| `prometheus.prometheusSpec.ruleSelector` | A selector to select which PrometheusRules to mount for loading alerting rules from. Until (excluding) Prometheus Operator v0.24.0 Prometheus Operator will migrate any legacy rule ConfigMaps to PrometheusRule custom resources selected by RuleSelector. Make sure it does not match any config maps that you do not want to be migrated. If {}, select all PrometheusRules | `{}` |
| `prometheus.prometheusSpec.scrapeInterval` | Interval between consecutive scrapes. | `""` |
| `prometheus.prometheusSpec.secrets` | Secrets is a list of Secrets in the same namespace as the Prometheus object, which shall be mounted into the Prometheus Pods. The Secrets are mounted into /etc/prometheus/secrets/<secret-name>. Secrets changes after initial creation of a Prometheus object are not reflected in the running Pods. To change the secrets mounted into the Prometheus Pods, the object must be deleted and recreated with the new list of secrets. | `[]` |
| `prometheus.prometheusSpec.securityContext` | SecurityContext holds pod-level security attributes and common container settings. This defaults to non root user with uid 1000 and gid 2000 in order to support migration from operator version <0.26. | `{"runAsNonRoot": true, "runAsUser": 1000, "fsGroup": 2000}` |
| `prometheus.prometheusSpec.serviceMonitorNamespaceSelector` | Namespaces to be selected for ServiceMonitor discovery. See [metav1.LabelSelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#labelselector-v1-meta) for usage | `{}` |
| `prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues` | If true, a nil or {} value for prometheus.prometheusSpec.serviceMonitorSelector will cause the prometheus resource to be created with selectors based on values in the helm deployment, which will also match the servicemonitors created | `true` |
| `prometheus.prometheusSpec.serviceMonitorSelector` | ServiceMonitors to be selected for target discovery. If {}, select all ServiceMonitors | `{}` |
| `prometheus.additionalPodMonitors` | List of `PodMonitor` objects to create. See https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#podmonitorspec | `[]` |
| `prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues` | If true, a nil or {} value for prometheus.prometheusSpec.podMonitorSelector will cause the prometheus resource to be created with selectors based on values in the helm deployment, which will also match the podmonitors created | `true` |
| `prometheus.prometheusSpec.podMonitorSelector` | PodMonitors to be selected for target discovery. If {}, select all PodMonitors | `{}` |
| `prometheus.prometheusSpec.podMonitorNamespaceSelector` | Namespaces to be selected for PodMonitor discovery. See [metav1.LabelSelector](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#labelselector-v1-meta) for usage | `{}` |
| `prometheus.prometheusSpec.storageSpec` | Storage spec to specify how storage shall be used. | `{}` |
| `prometheus.prometheusSpec.thanos` | Thanos configuration allows configuring various aspects of a Prometheus server in a Thanos environment. This section is experimental, it may change significantly without deprecation notice in any release.This is experimental and may change significantly without backward compatibility in any release. See https://github.com/coreos/prometheus-operator/blob/master/Documentation/api.md#thanosspec | `{}` |
| `prometheus.prometheusSpec.tolerations` | If specified, the pod's tolerations. | `[]` |
| `prometheus.service.additionalPorts` |  Additional Prometheus Service ports to add for NodePort service type | `[]` |
| `prometheus.service.annotations` |  Prometheus Service Annotations | `{}` |
| `prometheus.service.clusterIP` | Prometheus service clusterIP IP | `""` |
| `prometheus.service.externalIPs` | List of IP addresses at which the Prometheus server service is available | `[]` |
| `prometheus.service.labels` |  Prometheus Service Labels | `{}` |
| `prometheus.service.loadBalancerIP` |  Prometheus Loadbalancer IP | `""` |
| `prometheus.service.loadBalancerSourceRanges` | Prometheus Load Balancer Source Ranges | `[]` |
| `prometheus.service.nodePort` |  Prometheus Service port for NodePort service type | `30090` |
| `prometheus.service.port` |  Port for Prometheus Service to listen on | `9090` |
| `prometheus.service.sessionAffinity` | Prometheus Service Session Affinity | `""` |
| `prometheus.service.targetPort` |  Prometheus Service internal port | `9090` |
| `prometheus.service.type` |  Prometheus Service type | `ClusterIP` |
| `prometheus.serviceAccount.create` | Create a default serviceaccount for prometheus to use | `true` |
| `prometheus.serviceAccount.name` | Name for prometheus serviceaccount | `""` |
| `prometheus.serviceAccount.annotations` | Annotations to add to the serviceaccount | `""` |
| `prometheus.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `prometheus.serviceMonitor.bearerTokenFile` | Bearer token used to scrape the Prometheus server | `nil` |
| `prometheus.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping the prometheus instance. | `` |
| `prometheus.serviceMonitor.relabelings` | The `relabel_configs` for scraping the prometheus instance. | `` |
| `prometheus.serviceMonitor.selfMonitor` | Create a `serviceMonitor` to automatically monitor the prometheus instance | `true` |
| `prometheus.servicePerReplica.annotations` | Prometheus per replica Service Annotations | `{}` |
| `prometheus.servicePerReplica.enabled` | If true, create a Service for each Prometheus server replica in the StatefulSet | `false` |
| `prometheus.servicePerReplica.labels` | Prometheus per replica Service Labels | `{}` |
| `prometheus.servicePerReplica.loadBalancerSourceRanges` | Prometheus per replica Service Loadbalancer Source Ranges | `[]` |
| `prometheus.servicePerReplica.nodePort` |  Prometheus per replica Service port for NodePort Service type | `30091` |
| `prometheus.servicePerReplica.port` |  Port for Prometheus per replica Service to listen on | `9090` |
| `prometheus.servicePerReplica.targetPort` |  Prometheus per replica Service internal port | `9090` |
| `prometheus.servicePerReplica.type` |  Prometheus per replica Service type | `ClusterIP` |

### Alertmanager
| Parameter | Description | Default |
| ----- | ----------- | ------ |
| `alertmanager.alertmanagerSpec.additionalPeers` | AdditionalPeers allows injecting a set of additional Alertmanagers to peer with to form a highly available cluster. | `[]` |
| `alertmanager.alertmanagerSpec.affinity` | Assign custom affinity rules to the alertmanager instance https://kubernetes.io/docs/concepts/configuration/assign-pod-node/ | `{}` |
| `alertmanager.alertmanagerSpec.configMaps` | ConfigMaps is a list of ConfigMaps in the same namespace as the Alertmanager object, which shall be mounted into the Alertmanager Pods. The ConfigMaps are mounted into /etc/alertmanager/configmaps/ | `[]` |
| `alertmanager.alertmanagerSpec.`configSecret | ConfigSecret is the name of a Kubernetes Secret in the same namespace as the Alertmanager object, which contains configuration for this Alertmanager instance. Defaults to 'alertmanager-' The secret is mounted into /etc/alertmanager/config. | `""` |
| `alertmanager.alertmanagerSpec.containers` | Containers allows injecting additional containers. This is meant to allow adding an authentication proxy to an Alertmanager pod. | `[]` |
| `alertmanager.alertmanagerSpec.externalUrl` | The external URL the Alertmanager instances will be available under. This is necessary to generate correct URLs. This is necessary if Alertmanager is not served from root of a DNS name. | `""` |
| `alertmanager.alertmanagerSpec.image.repository` | Base image that is used to deploy pods, without tag. | `quay.io/prometheus/alertmanager` |
| `alertmanager.alertmanagerSpec.image.tag` | Tag of Alertmanager container image to be deployed. | `v0.19.0` |
| `alertmanager.alertmanagerSpec.listenLocal` | ListenLocal makes the Alertmanager server listen on loopback, so that it does not bind against the Pod IP. Note this is only for the Alertmanager UI, not the gossip communication. | `false` |
| `alertmanager.alertmanagerSpec.logFormat` | Log format for Alertmanager to be configured with. | `logfmt` |
| `alertmanager.alertmanagerSpec.logLevel` | Log level for Alertmanager to be configured with. | `info` |
| `alertmanager.alertmanagerSpec.nodeSelector` | Define which Nodes the Pods are scheduled on. | `{}` |
| `alertmanager.alertmanagerSpec.paused` | If set to true all actions on the underlying managed objects are not going to be performed, except for delete actions. | `false` |
| `alertmanager.alertmanagerSpec.podAntiAffinityTopologyKey` | If anti-affinity is enabled sets the topologyKey to use for anti-affinity. This can be changed to, for example `failure-domain.beta.kubernetes.io/zone`| `kubernetes.io/hostname` |
| `alertmanager.alertmanagerSpec.podAntiAffinity` | Pod anti-affinity can prevent the scheduler from placing Prometheus replicas on the same node. The default value "soft" means that the scheduler should *prefer* to not schedule two replica pods onto the same node but no guarantee is provided. The value "hard" means that the scheduler is *required* to not schedule two replica pods onto the same node. The value "" will disable pod anti-affinity so that no anti-affinity rules will be configured. | `""` |
| `alertmanager.alertmanagerSpec.podMetadata` | Standard object’s metadata. More info: https://github.com/kubernetes/community/blob/master/contributors/devel/api-conventions.md#metadata Metadata Labels and Annotations gets propagated to the prometheus pods. | `{}` |
| `alertmanager.alertmanagerSpec.priorityClassName` | Priority class assigned to the Pods | `""` |
| `alertmanager.alertmanagerSpec.replicas` | Size is the expected size of the alertmanager cluster. The controller will eventually make the size of the running cluster equal to the expected size. | `1` |
| `alertmanager.alertmanagerSpec.resources` | Define resources requests and limits for single Pods. | `{}` |
| `alertmanager.alertmanagerSpec.retention` | Time duration Alertmanager shall retain data for. Value must match the regular expression `[0-9]+(ms\|s\|m\|h)` (milliseconds seconds minutes hours). | `120h` |
| `alertmanager.alertmanagerSpec.routePrefix` | The route prefix Alertmanager registers HTTP handlers for. This is useful, if using ExternalURL and a proxy is rewriting HTTP routes of a request, and the actual ExternalURL is still true, but the server serves requests under a different route prefix. For example for use with `kubectl proxy`. | `/` |
| `alertmanager.alertmanagerSpec.secrets` | Secrets is a list of Secrets in the same namespace as the Alertmanager object, which shall be mounted into the Alertmanager Pods. The Secrets are mounted into /etc/alertmanager/secrets/<secret-name>. | `[]` |
| `alertmanager.alertmanagerSpec.securityContext` | SecurityContext holds pod-level security attributes and common container settings. This defaults to non root user with uid 1000 and gid 2000 in order to support migration from operator version < 0.26 | `{"runAsNonRoot": true, "runAsUser": 1000, "fsGroup": 2000}` |
| `alertmanager.alertmanagerSpec.storage` | Storage is the definition of how storage will be used by the Alertmanager instances. | `{}` |
| `alertmanager.alertmanagerSpec.tolerations` | If specified, the pod's tolerations. | `[]` |
| `alertmanager.alertmanagerSpec.useExistingSecret` | Use an existing secret for configuration (all defined config from values.yaml will be ignored) | `false` |
| `alertmanager.config` | Provide YAML to configure Alertmanager. See https://prometheus.io/docs/alerting/configuration/#configuration-file. The default provided works to suppress the Watchdog alert from `defaultRules.create` | `{"global":{"resolve_timeout":"5m"},"route":{"group_by":["job"],"group_wait":"30s","group_interval":"5m","repeat_interval":"12h","receiver":"null","routes":[{"match":{"alertname":"Watchdog"},"receiver":"null"}]},"receivers":[{"name":"null"}]}` |
| `alertmanager.enabled` | Deploy alertmanager | `true` |
| `alertmanager.ingress.annotations` | Alertmanager Ingress annotations | `{}` |
| `alertmanager.ingress.enabled` | If true, Alertmanager Ingress will be created | `false` |
| `alertmanager.ingress.hosts` | Alertmanager Ingress hostnames | `[]` |
| `alertmanager.ingress.labels` | Alertmanager Ingress additional labels | `{}` |
| `alertmanager.ingress.paths` | Alertmanager Ingress paths | `[]` |
| `alertmanager.ingress.tls` | Alertmanager Ingress TLS configuration (YAML) | `[]` |
| `alertmanager.podDisruptionBudget.enabled` | If true, create a pod disruption budget for Alertmanager pods. The created resource cannot be modified once created - it must be deleted to perform a change | `false` |
| `alertmanager.podDisruptionBudget.maxUnavailable` | Maximum number / percentage of pods that may be made unavailable | `""` |
| `alertmanager.podDisruptionBudget.minAvailable` | Minimum number / percentage of pods that should remain scheduled | `1` |
| `alertmanager.secret.annotations` | Alertmanager Secret annotations | `{}` |
| `alertmanager.service.annotations` | Alertmanager Service annotations | `{}` |
| `alertmanager.service.clusterIP` | Alertmanager service clusterIP IP | `""` |
| `alertmanager.service.externalIPs` | List of IP addresses at which the Alertmanager server service is available | `[]` |
| `alertmanager.service.labels` |  Alertmanager Service Labels | `{}` |
| `alertmanager.service.loadBalancerIP` |  Alertmanager Loadbalancer IP | `""` |
| `alertmanager.service.loadBalancerSourceRanges` | Alertmanager Load Balancer Source Ranges | `[]` |
| `alertmanager.service.nodePort` | Alertmanager Service port for NodePort service type | `30903` |
| `alertmanager.service.port` | Port for Alertmanager Service to listen on | `9093` |
| `alertmanager.service.type` | Alertmanager Service type | `ClusterIP` |
| `alertmanager.serviceAccount.create` | Create a `serviceAccount` for alertmanager | `true` |
| `alertmanager.serviceAccount.name` | Name for Alertmanager service account | `""` |
| `alertmanager.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `alertmanager.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping the alertmanager instance. | `` |
| `alertmanager.serviceMonitor.relabelings` | The `relabel_configs` for scraping the alertmanager instance. | `` |
| `alertmanager.serviceMonitor.selfMonitor` | Create a `serviceMonitor` to automatically monitor the alartmanager instance | `true` |
| `alertmanager.tplConfig` | Pass the Alertmanager configuration directives through Helm's templating engine. If the Alertmanager configuration contains Alertmanager templates, they'll need to be properly escaped so that they are not interpreted by Helm | `false` |

### Grafana
This is not a full list of the possible values.

For a full list of configurable values please refer to the [Grafana chart](https://github.com/helm/charts/tree/master/stable/grafana#configuration).

| Parameter | Description | Default |
| ----- | ----------- | ------ |
| `grafana.additionalDataSources` | Configure additional grafana datasources | `[]` |
| `grafana.adminPassword` | Admin password to log into the grafana UI | "prom-operator" |
| `grafana.defaultDashboardsEnabled` | Deploy default dashboards. These are loaded using the sidecar | `true` |
| `grafana.enabled` | If true, deploy the grafana sub-chart | `true` |
| `grafana.extraConfigmapMounts` | Additional grafana server configMap volume mounts | `[]` |
| `grafana.grafana.ini` | Grafana's primary configuration | `{}`
| `grafana.image.tag` | Image tag. (`Must be >= 5.0.0`) | `6.2.5` |
| `grafana.ingress.annotations` | Ingress annotations for Grafana | `{}` |
| `grafana.ingress.enabled` | Enables Ingress for Grafana | `false` |
| `grafana.ingress.hosts` | Ingress accepted hostnames for Grafana| `[]` |
| `grafana.ingress.labels` | Custom labels for Grafana Ingress | `{}` |
| `grafana.ingress.tls` | Ingress TLS configuration for Grafana | `[]` |
| `grafana.rbac.pspUseAppArmor` | Enforce AppArmor in created PodSecurityPolicy (requires rbac.pspEnabled) | `true` |
| `grafana.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping the grafana instance. | `` |
| `grafana.serviceMonitor.relabelings` | The `relabel_configs` for scraping the grafana instance. | `` |
| `grafana.serviceMonitor.selfMonitor` | Create a `serviceMonitor` to automatically monitor the grafana instance | `true` |
| `grafana.sidecar.dashboards.enabled` | Enable the Grafana sidecar to automatically load dashboards with a label `{{ grafana.sidecar.dashboards.label }}=1` | `true` |
| `grafana.sidecar.dashboards.label` | If the sidecar is enabled, configmaps with this label will be loaded into Grafana as dashboards | `grafana_dashboard` |
| `grafana.sidecar.datasources.annotations` | Create annotations on datasource configmaps | `{}` |
| `grafana.sidecar.datasources.createPrometheusReplicasDatasources` | Create datasource for each Pod of Prometheus StatefulSet i.e. `Prometheus-0`, `Prometheus-1` | `false` |
| `grafana.sidecar.datasources.defaultDatasourceEnabled` | Enable Grafana `Prometheus` default datasource | `true` |
| `grafana.sidecar.datasources.enabled` | Enable the Grafana sidecar to automatically load datasources with a label `{{ grafana.sidecar.datasources.label }}=1` | `true` |
| `grafana.sidecar.datasources.label` | If the sidecar is enabled, configmaps with this label will be loaded into Grafana as datasources configurations | `grafana_datasource` |

### Exporters
| Parameter | Description | Default |
| ----- | ----------- | ------ |
| `coreDns.enabled` | Deploy coreDns scraping components. Use either this or kubeDns | true |
| `coreDns.service.port` | CoreDns port | `9153` |
| `coreDns.service.selector` | CoreDns service selector | `{"k8s-app" : "kube-dns" }` |
| `coreDns.service.targetPort` | CoreDns targetPort | `9153` |
| `coreDns.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `coreDns.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping CoreDns. | `` |
| `coreDns.serviceMonitor.relabelings` | The `relabel_configs` for scraping CoreDNS. | `` |
| `kube-state-metrics.podSecurityPolicy.enabled` | Create pod security policy resource for kube-state-metrics. | `true` |
| `kube-state-metrics.rbac.create` | Create RBAC components in kube-state-metrics. See `global.rbac.create` | `true` |
| `kubeApiServer.enabled` | Deploy `serviceMonitor` to scrape the Kubernetes API server | `true` |
| `kubeApiServer.relabelings` | Relablings for the API Server ServiceMonitor | `[]` |
| `kubeApiServer.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `kubeApiServer.serviceMonitor.jobLabel` | The name of the label on the target service to use as the job name in prometheus | `component` |
| `kubeApiServer.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping the Kubernetes API server. | `` |
| `kubeApiServer.serviceMonitor.relabelings` | The `relabel_configs` for scraping the Kubernetes API server. | `` |
| `kubeApiServer.serviceMonitor.selector` | The service selector | `{"matchLabels":{"component":"apiserver","provider":"kubernetes"}}` |
| `kubeApiServer.tlsConfig.insecureSkipVerify` | Skip TLS certificate validation when scraping | `false` |
| `kubeApiServer.tlsConfig.serverName` | Name of the server to use when validating TLS certificate | `kubernetes` |
| `kubeControllerManager.enabled` | Deploy a `service` and `serviceMonitor` to scrape the Kubernetes controller-manager | `true` |
| `kubeControllerManager.endpoints` | Endpoints where Controller-manager runs. Provide this if running Controller-manager outside the cluster | `[]` |
| `kubeControllerManager.service.port` | Controller-manager port for the service runs on | `10252` |
| `kubeControllerManager.service.selector` | Controller-manager service selector | `{"component" : "kube-controller-manager" }` |
| `kubeControllerManager.service.targetPort` | Controller-manager targetPort for the service runs on | `10252` |
| `kubeControllerManager.serviceMonitor.https` | Controller-manager service scrape over https | `false` |
| `kubeControllerManager.serviceMonitor.insecureSkipVerify` | Skip TLS certificate validation when scraping | `null` |
| `kubeControllerManager.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `kubeControllerManager.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping the scheduler. | `` |
| `kubeControllerManager.serviceMonitor.relabelings` | The `relabel_configs` for scraping the scheduler. | `` |
| `kubeControllerManager.serviceMonitor.serverName` | Name of the server to use when validating TLS certificate | `null` |
| `kubeDns.enabled` | Deploy kubeDns scraping components. Use either this or coreDns| `false` |
| `kubeDns.service.dnsmasq.port` | Dnsmasq service port | `10054` |
| `kubeDns.service.dnsmasq.targetPort` | Dnsmasq service targetPort | `10054` |
| `kubeDns.service.skydns.port` | Skydns service port | `10055` |
| `kubeDns.service.skydns.targetPort` | Skydns service targetPort | `10055` |
| `kubeDns.service.selector` | kubeDns service selector | `{"k8s-app" : "kube-dns" }` |
| `kubeDns.serviceMonitor.dnsmasqMetricRelabelings` | The `metric_relabel_configs` for scraping dnsmasq kubeDns. | `` |
| `kubeDns.serviceMonitor.dnsmasqRelabelings` | The `relabel_configs` for scraping dnsmasq kubeDns. | `` |
| `kubeDns.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `kubeDns.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping kubeDns. | `` |
| `kubeDns.serviceMonitor.relabelings` | The `relabel_configs` for scraping kubeDns. | `` |
| `kubeEtcd.enabled` | Deploy components to scrape etcd | `true` |
| `kubeEtcd.endpoints` | Endpoints where etcd runs. Provide this if running etcd outside the cluster | `[]` |
| `kubeEtcd.service.port` | Etcd port | `4001` |
| `kubeEtcd.service.selector` | Selector for etcd if running inside the cluster | `{"component":"etcd"}` |
| `kubeEtcd.service.targetPort` | Etcd targetPort | `4001` |
| `kubeEtcd.serviceMonitor.caFile` | Certificate authority file to use when connecting to etcd. See `prometheus.prometheusSpec.secrets` | `""` |
| `kubeEtcd.serviceMonitor.certFile` | Client certificate file to use when connecting to etcd. See `prometheus.prometheusSpec.secrets` | `""` |
| `kubeEtcd.serviceMonitor.insecureSkipVerify` | Skip validating etcd TLS certificate when scraping | `false` |
| `kubeEtcd.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `kubeEtcd.serviceMonitor.keyFile` | Client key file to use when connecting to etcd.  See `prometheus.prometheusSpec.secrets` | `""` |
| `kubeEtcd.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping Etcd. | `` |
| `kubeEtcd.serviceMonitor.relabelings` | The `relabel_configs` for scraping Etcd. | `` |
| `kubeEtcd.serviceMonitor.scheme` | Etcd servicemonitor scheme | `http` |
| `kubeEtcd.serviceMonitor.serverName` | Etcd server name to validate certificate against when scraping | `""` |
| `kubeProxy.enabled` | Deploy a `service` and `serviceMonitor` to scrape the Kubernetes proxy | `true` |
| `kubeProxy.endpoints` | Endpoints where proxy runs. Provide this if running proxy outside the cluster | `[]` |
| `kubeProxy.service.port` | Kubernetes proxy port for the service runs on | `10249` |
| `kubeProxy.service.selector` | Kubernetes proxy service selector | `{"k8s-app" : "kube-proxy" }` |
| `kubeProxy.service.targetPort` | Kubernetes proxy targetPort for the service runs on | `10249` |
| `kubeProxy.serviceMonitor.https` | Kubernetes proxy service scrape over https | `false` |
| `kubeProxy.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `kubeProxy.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping the Kubernetes proxy. | `` |
| `kubeProxy.serviceMonitor.relabelings` | The `relabel_configs` for scraping the Kubernetes proxy. | `` |
| `kubeScheduler.enabled` | Deploy a `service` and `serviceMonitor` to scrape the Kubernetes scheduler | `true` |
| `kubeScheduler.endpoints` | Endpoints where scheduler runs. Provide this if running scheduler outside the cluster | `[]` |
| `kubeScheduler.service.port` | Scheduler port for the service runs on | `10251` |
| `kubeScheduler.service.selector` | Scheduler service selector | `{"component" : "kube-scheduler" }` |
| `kubeScheduler.service.targetPort` | Scheduler targetPort for the service runs on | `10251` |
| `kubeScheduler.serviceMonitor.https` | Scheduler service scrape over https | `false` |
| `kubeScheduler.serviceMonitor.insecureSkipVerify` | Skip TLS certificate validation when scraping | `null` |
| `kubeScheduler.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `kubeScheduler.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping the Kubernetes scheduler. | `` |
| `kubeScheduler.serviceMonitor.relabelings` | The `relabel_configs` for scraping the Kubernetes scheduler. | `` |
| `kubeScheduler.serviceMonitor.serverName` | Name of the server to use when validating TLS certificate | `null` |
| `kubeStateMetrics.enabled` | Deploy the `kube-state-metrics` chart and configure a servicemonitor to scrape | `true` |
| `kubeStateMetrics.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `kubeStateMetrics.serviceMonitor.metricRelabelings` | Metric relablings for the `kube-state-metrics` ServiceMonitor | `[]` |
| `kubeStateMetrics.serviceMonitor.relabelings` | The `relabel_configs` for scraping `kube-state-metrics`. | `` |
| `kubelet.enabled` | Deploy servicemonitor to scrape the kubelet service. See also `prometheusOperator.kubeletService` | `true` |
| `kubelet.namespace` | Namespace where the kubelet is deployed. See also `prometheusOperator.kubeletService.namespace` | `kube-system` |
| `kubelet.serviceMonitor.cAdvisorMetricRelabelings` | The `metric_relabel_configs` for scraping cAdvisor. | `` |
| `kubelet.serviceMonitor.cAdvisorRelabelings` | The `relabel_configs` for scraping cAdvisor. | `` |
| `kubelet.serviceMonitor.https` | Enable scraping of the kubelet over HTTPS. For more information, see https://github.com/coreos/prometheus-operator/issues/926 | `true` |
| `kubelet.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `kubelet.serviceMonitor.metricRelabelings` | The `metric_relabel_configs` for scraping kubelet. | `` |
| `kubelet.serviceMonitor.relabelings` | The `relabel_configs` for scraping kubelet. | `` |
| `nodeExporter.enabled` | Deploy the `prometheus-node-exporter` and scrape it | `true` |
| `nodeExporter.jobLabel` | The name of the label on the target service to use as the job name in prometheus. See `prometheus-node-exporter.podLabels.jobLabel=node-exporter` default | `jobLabel` |
| `nodeExporter.serviceMonitor.interval` | Scrape interval. If not set, the Prometheus default scrape interval is used | `nil` |
| `nodeExporter.serviceMonitor.scrapeTimeout` | How long until a scrape request times out. If not set, the Prometheus default scape timeout is used | `nil` |
| `nodeExporter.serviceMonitor.metricRelabelings` | Metric relablings for the `prometheus-node-exporter` ServiceMonitor | `[]` |
| `nodeExporter.serviceMonitor.relabelings` | The `relabel_configs` for scraping the `prometheus-node-exporter`. | `` |
| `prometheus-node-exporter.extraArgs` | Additional arguments for the node exporter container | `["--collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker/.+)($|/)", "--collector.filesystem.ignored-fs-types=^(autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$"]` |
| `prometheus-node-exporter.podLabels` | Additional labels for pods in the DaemonSet | `{"jobLabel":"node-exporter"}` |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install --name my-release stable/prometheus-operator --set prometheusOperator.enabled=true
```

Alternatively, one or more YAML files that specify the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install --name my-release stable/prometheus-operator -f values1.yaml,values2.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)


## PrometheusRules Admission Webhooks

With Prometheus Operator version 0.30+, the core Prometheus Operator pod exposes an endpoint that will integrate with the `validatingwebhookconfiguration` Kubernetes feature to prevent malformed rules from being added to the cluster.

### How the Chart Configures the Hooks
A validating and mutating webhook configuration requires the endpoint to which the request is sent to use TLS. It is possible to set up custom certificates to do this, but in most cases, a self-signed certificate is enough. The setup of this component requires some more complex orchestration when using helm. The steps are created to be idempotent and to allow turning the feature on and off without running into helm quirks.
1. A pre-install hook provisions a certificate into the same namespace using a format compatible with provisioning using end-user certificates. If the certificate already exists, the hook exits.
2. The prometheus operator pod is configured to use a TLS proxy container, which will load that certificate.
3. Validating and Mutating webhook configurations are created in the cluster, with their failure mode set to Ignore. This allows rules to be created by the same chart at the same time, even though the webhook has not yet been fully set up - it does not have the correct CA field set.
4. A post-install hook reads the CA from the secret created by step 1 and patches the Validating and Mutating webhook configurations. This process will allow a custom CA provisioned by some other process to also be patched into the webhook configurations. The chosen failure policy is also patched into the webhook configurations

### Alternatives
It should be possible to use [jetstack/cert-manager](https://github.com/jetstack/cert-manager) if a more complete solution is required, but it has not been tested.

### Limitations
Because the operator can only run as a single pod, there is potential for this component failure to cause rule deployment failure. Because this risk is outweighed by the benefit of having validation, the feature is enabled by default.

## Developing Prometheus Rules and Grafana Dashboards

This chart Grafana Dashboards and Prometheus Rules are just a copy from coreos/prometheus-operator and other sources, synced (with alterations) by scripts in [hack](hack) folder. In order to introduce any changes you need to first [add them to the original repo](https://github.com/coreos/kube-prometheus/blob/master/docs/developing-prometheus-rules-and-grafana-dashboards.md) and then sync there by scripts.

## Further Information

For more in-depth documentation of configuration options meanings, please see
- [Prometheus Operator](https://github.com/coreos/prometheus-operator)
- [Prometheus](https://prometheus.io/docs/introduction/overview/)
- [Grafana](https://github.com/helm/charts/tree/master/stable/grafana#grafana-helm-chart)

# Migrating from coreos/prometheus-operator chart

The multiple charts have been combined into a single chart that installs prometheus operator, prometheus, alertmanager, grafana as well as the multitude of exporters necessary to monitor a cluster.

There is no simple and direct migration path between the charts as the changes are extensive and intended to make the chart easier to support.

The capabilities of the old chart are all available in the new chart, including the ability to run multiple prometheus instances on a single cluster - you will need to disable the parts of the chart you do not wish to deploy.

You can check out the tickets for this change [here](https://github.com/coreos/prometheus-operator/issues/592) and [here](https://github.com/helm/charts/pull/6765).

## High-level overview of Changes
The chart has 3 dependencies, that can be seen in the chart's requirements file:
https://github.com/helm/charts/blob/master/stable/prometheus-operator/requirements.yaml

### Node-Exporter, Kube-State-Metrics
These components are loaded as dependencies into the chart. The source for both charts is found in the same repository. They are relatively simple components.

### Grafana
The Grafana chart is more feature-rich than this chart - it contains a sidecar that is able to load data sources and dashboards from configmaps deployed into the same cluster. For more information check out the [documentation for the chart](https://github.com/helm/charts/tree/master/stable/grafana)

### Coreos CRDs
The CRDs are provisioned using crd-install hooks, rather than relying on a separate chart installation. If you already have these CRDs provisioned and don't want to remove them, you can disable the CRD creation by these hooks by passing `prometheusOperator.createCustomResource=false` (not required if using Helm v3).

### Kubelet Service
Because the kubelet service has a new name in the chart, make sure to clean up the old kubelet service in the `kube-system` namespace to prevent counting container metrics twice.

### Persistent Volumes
If you would like to keep the data of the current persistent volumes, it should be possible to attach existing volumes to new PVCs and PVs that are created using the conventions in the new chart. For example, in order to use an existing Azure disk for a helm release called `prometheus-migration` the following resources can be created:
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pvc-prometheus-migration-prometheus-0
spec:
  accessModes:
  - ReadWriteOnce
  azureDisk:
    cachingMode: None
    diskName: pvc-prometheus-migration-prometheus-0
    diskURI: /subscriptions/f5125d82-2622-4c50-8d25-3f7ba3e9ac4b/resourceGroups/sample-migration-resource-group/providers/Microsoft.Compute/disks/pvc-prometheus-migration-prometheus-0
    fsType: ""
    kind: Managed
    readOnly: false
  capacity:
    storage: 1Gi
  persistentVolumeReclaimPolicy: Delete
  storageClassName: prometheus
  volumeMode: Filesystem
```
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app: prometheus
    prometheus: prometheus-migration-prometheus
  name: prometheus-prometheus-migration-prometheus-db-prometheus-prometheus-migration-prometheus-0
  namespace: monitoring
spec:
  accessModes:
  - ReadWriteOnce
  dataSource: null
  resources:
    requests:
      storage: 1Gi
  storageClassName: prometheus
  volumeMode: Filesystem
  volumeName: pvc-prometheus-migration-prometheus-0
status:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1Gi
```

The PVC will take ownership of the PV and when you create a release using a persistent volume claim template it will use the existing PVCs as they match the naming convention used by the chart. For other cloud providers similar approaches can be used.

### KubeProxy

The metrics bind address of kube-proxy is default to `127.0.0.1:10249` that prometheus instances **cannot** access to. You should expose metrics by changing `metricsBindAddress` field value to `0.0.0.0:10249` if you want to collect them.

Depending on the cluster, the relevant part `config.conf` will be in ConfigMap `kube-system/kube-proxy` or `kube-system/kube-proxy-config`. For example:

```
kubectl -n kube-system edit cm kube-proxy
```

```
apiVersion: v1
data:
  config.conf: |-
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    kind: KubeProxyConfiguration
    # ...
    # metricsBindAddress: 127.0.0.1:10249
    metricsBindAddress: 0.0.0.0:10249
    # ...
  kubeconfig.conf: |-
    # ...
kind: ConfigMap
metadata:
  labels:
    app: kube-proxy
  name: kube-proxy
  namespace: kube-system
```

# Thanos

Thanos is a set of components that can be composed into a highly available metric system with unlimited storage capacity, which can be added seamlessly on top of existing Prometheus deployments.

Thanos leverages the Prometheus 2.0 storage format to cost-efficiently store historical metric data in any object storage while retaining fast query latencies. Additionally, it provides a global query view across all Prometheus installations and can merge data from Prometheus HA pairs on the fly.

Concretely the aims of the project are:

- Global query view of metrics.
- Unlimited retention of metrics.
- High availability of components, including Prometheus.

## Helm Chart

This chart is in **Beta** state to provide easy installation via Helm chart.
Things that we are improving in near future:
- [ ] Automatic TLS generation for communicating between in-cluster components
- [ ] Support for tracing configuration
- [ ] Grafana dashboards
- [ ] Informative NOTES.txt

## Architecture

This Chart will install a complete [Thanos](https://github.com/improbable-eng/thanos) solution. To understand how Thanos works please read it's official [Architecture design](https://github.com/improbable-eng/thanos/blob/master/docs/design.md).

## Installing the Chart

Add Banzai Cloud repository:

```bash
$ helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com
```

## Storage examples

### Example GCS configuration for `object-store.yaml`
```
type: GCS
  config:
    bucket: "thanos"
    service_account: |-
      {
        "type": "service_account",
        "project_id": "project",
        "private_key_id": "abcdefghijklmnopqrstuvwxyz12345678906666",
        "private_key": "-----BEGIN PRIVATE KEY-----\...\n-----END PRIVATE KEY-----\n",
        "client_email": "project@thanos.iam.gserviceaccount.com",
        "client_id": "123456789012345678901",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/thanos%40gitpods.iam.gserviceaccount.com"
      }
```

### Example S3 configuration for `object-store.yaml`
This is an example configuration using thanos with S3. Check endpoints here: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region

```
type: S3
config:
  bucket: ""
  endpoint: ""
  region: ""
  access_key: ""
  insecure: false
  signature_version2: false
  encrypt_sse: false
  secret_key: ""
  put_user_metadata: {}
  http_config:
    idle_conn_timeout: 0s
    response_header_timeout: 0s
    insecure_skip_verify: false
  trace:
    enable: false
  part_size: 0
```

### Example Azure configuration for `object-store.yaml`

```
type: AZURE
config:
  storage_account: ""
  storage_account_key: ""
  container: ""
  endpoint: ""
    max_retries: 0
```
Create the Service Account and Bucket at Google cloud.

#### Install the chart:
```bash
helm install banzaicloud-stable/thanos --name thanos -f my-values.yaml --set-file objstoreFile=object-store.yaml

```

Visit the Bucket browser
```bash
kubectl port-forward svc/thanos-bucket 8080 &
open http://localhost:8080
```

## Install prometheus-operator

Extra configuration for prometheus operator.

> Note: Prometheus-operator and Thanos **MUST** be in the same namespace.

```yaml
prometheus:
  prometheusSpec:
    thanos:
      image: quay.io/thanos/thanos:v0.9.0
      version: v0.9.0
      objectStorageConfig:
        name: thanos
        key: object-store.yaml
```

Install prometheus-operator

```bash
helm install stable/prometheus-operator -f thanos-sidecar.yaml
```

# Configuration

This section describes the values available

## General
|Name|Description| Default Value|
|----|-----------|--------------|
| image.repository | Thanos image repository and name | 'quay.io/thanos/thanos'   **For Thanos version 0.6.0 or older change this to 'improbable/thanos'** |
| image.tag | Thanos image tag | v0.9.0 |
| image.pullPolicy | Image Kubernetes pull policy | IfNotPresent |
| objstore | Configuration for the backend object storage in yaml format. Mutually exclusive with other objstore options. | {} |
| objstoreFile | Configuration for the backend object storage in string format. Mutually exclusive with other objstore options. | "" |
| objstoreSecretOverride | Configuration for the backend object storage in an existing secret. Mutually exclusive with other objstore options.  | "" |

## Common settings for all components

These setting applicable to nearly all components.

|Name|Description| Default Value|
|----|-----------|--------------|
| $component.labels | Additional labels to the Pod | {} |
| $component.annotations | Additional annotations to the Pod | {} |
| $component.deploymentLabels | Additional labels to the deployment | {} |
| $component.deploymentAnnotations | Additional annotations to the deployment | {} |
| $component.extraEnv | Add extra environment variables | [] |
| $component.metrics.annotations.enabled | Prometheus annotation for component | false |
| $component.metrics.serviceMonitor.enabled | Prometheus ServiceMonitor definition for component | false |
| $component.securityContext | SecurityContext for Pod | {} |
| $component.resources | Resource definition for container | {} |
| $component.tolerations | [Node tolerations for server scheduling to nodes with taints](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/) | {} |
| $component.nodeSelector | [Node labels for compact pod assignment](https://kubernetes.io/docs/user-guide/node-selection/) | {} |
| $component.affinity | [Pod affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#node-affinity) | {} |
| $component.grpc.port | grpc listen port number | 10901 |
| $component.grpc.service.annotations | Service definition for grpc service | {} |
| $component.grpc.ingress.enabled | Set up ingress for the grpc service | false |
| $component.grpc.ingress.annotations | Add annotations to ingress | {} |
| $component.grpc.ingress.labels | Add labels to ingress | {} |
| $component.grpc.ingress.path | Ingress path | "/" |
| $component.grpc.ingress.hosts | Ingress hosts | [] |
| $component.grpc.ingress.tls | Ingress TLS configuration | [] |
| $component.http.port | http listen port number | 10902 |
| $component.http.service.annotations | Service definition for http service | {} |
| $component.http.ingress.enabled | Set up ingress for the http service | false |
| $component.http.ingress.annotations | Add annotations to ingress | {} |
| $component.http.ingress.labels | Add labels to ingress | {} |
| $component.http.ingress.path | Ingress path | "/" |
| $component.http.ingress.hosts | Ingress hosts | [] |
| $component.http.ingress.tls | Ingress TLS configuration | [] |

## Store

These values are just samples, for more fine-tuning please check the values.yaml.

|Name|Description| Default Value|
|----|-----------|--------------|
| store.enabled | Enable component | true |
| store.replicaCount | Pod replica count | 1 |
| store.logLevel | Log level | info |
| store.logFormat | Log format to use. Possible options: logfmt or json. | logfmt |
| store.indexCacheSize | Maximum size of items held in the index cache. | 250MB |
| store.chunkPoolSize | Maximum size of concurrently allocatable bytes for chunks. | 2GB |
| store.grpcSeriesSampleLimit | Maximum amount of samples returned via a single series call. 0 means no limit. NOTE: for efficiency we take 120 as the number of samples in chunk (it cannot be bigger than that), so the actual number of samples might be lower, even though the maximum could be hit. | 0 |
| store.grpcSeriesMaxConcurrency | Maximum number of concurrent Series calls. | 20 |
| store.syncBlockDuration |Repeat interval for syncing the blocks between local and remote view. | 3m |
| store.blockSyncConcurrency | Number of goroutines to use when syncing blocks from object storage. | 20 |
| store.extraEnv | Add extra environment variables | [] |
| store.extraArgs | Add extra arguments | [] |
| store.serviceAccount | Name of the Kubernetes service account to use | "" |
| store.livenessProbe  | Set up liveness probe for store available for Thanos v0.8.0+) |  {} |
| store.readinessProbe  | Set up readinessProbe for store (available for Thanos v0.8.0+) | {}  |
| timePartioning   |  list of min/max time for store partitions. See more details below. Setting this will create mutlipale thanos store deployments based on the number of items in the list  | [{min: "", max: ""}] |

### Store time partions
Thanos store supports partition based on time.
Setting time partitions will create n number of store deployment based on the number of items in the list. Each item must contain min and max time for querying in the supported format (see details here See details at https://thanos.io/components/store.md/#time-based-partioning ).
Leaving this empty list ([]) will create a single store for all data.
Example - This will create 3 stores:
```yaml
timePartioning:
  # One store for data older than 6 weeks
  - min: ""
    max: -6w
  # One store for data newer than 6 weeks and older than 2 weeks
  - min: -6w
    max: -2w
  # One store for data newer than 2 weeks
  - min: -2w
    max: ""
```


## Query

|Name|Description| Default Value|
|----|-----------|--------------|
| query.enabled | Enable component | true |
| query.replicaCount | Pod replica count | 1 |
| query.logLevel | Log level | info |
| query.logFormat | Log format to use. Possible options: logfmt or json. | logfmt |
| query.replicaLabel | Label to treat as a replica indicator along which data is deduplicated. Still you will be able to query without deduplication using 'dedup=false' parameter. | "" |
| query.autoDownsampling | Enable --query.auto-downsampling option for query. | false |
| query.webRoutePrefix |Prefix for API and UI endpoints. This allows thanos UI to be served on a sub-path. This option is analogous to --web.route-prefix of Promethus. | "" |
| query.webExternalPrefix |Static prefix for all HTML links and redirect URLs in the UI query web interface. Actual endpoints are still served on / or the web.route-prefix. This allows thanos UI to be served behind a reverse proxy that strips a URL sub-path | "" |
| query.webPrefixHeader | Name of HTTP request header used for dynamic prefixing of UI links and redirects. This option is ignored if web.external-prefix argument is set. Security risk: enable this option only if a reverse proxy in front of thanos is resetting the header. The --web.prefix-header=X-Forwarded-Prefix option can be useful, for example, if Thanos UI is served via Traefik reverse proxy with PathPrefixStrip option enabled, which sends the stripped prefix value in X-Forwarded-Prefix header. This allows thanos UI to be served on a sub-path | "" |
| query.storeDNSResolver | Custome DNS resolver because of [issue](https://github.com/improbable-eng/thanos/issues/1015) | miekgdns |
| query.storeDNSDiscovery | Enable DNS discovery for stores | true |
| query.sidecarDNSDiscovery | Enable DNS discovery for sidecars (this is for the chart built-in sidecar service) | true |
| query.stores | Addresses of statically configured store API servers (repeatable). The scheme may be prefixed with 'dns+' or 'dnssrv+' to detect store API servers through respective DNS lookups. | [] |
| query.serviceDiscoveryFiles | Path to files that contains addresses of store API servers. The path can be a glob pattern (repeatable). | [] |
| query.serviceDiscoveryFileConfigMaps | Names of configmaps that contain addresses of store API servers, used for file service discovery. | [] |
| query.serviceDiscoveryInterval | Refresh interval to re-read file SD files. It is used as a resync fallback. | 5m |
| query.extraEnv | Add extra environment variables | [] |
| query.extraArgs | Add extra arguments | [] |
| query.podDisruptionBudget.enabled | Enabled and config podDisruptionBudget resource for this component | false |
| query.podDisruptionBudget.minAvailable | Minimum number of available query pods for PodDisruptionBudget | 1 |
| query.podDisruptionBudget.maxUnavailable | Maximum number of unavailable query pods for PodDisruptionBudget | [] |
| query.autoscaling.enabled | Enabled and config horizontalPodAutoscaling resource for this component | false |
| query.autoscaling.minReplicas |	If autoscaling enabled, this field sets minimum replica count |	2 |
| query.autoscaling.maxReplicas |	If autoscaling enabled, this field sets maximum replica count |	3 |
| query.autoscaling.targetCPUUtilizationPercentage | 	Target CPU utilization percentage to scale | 50 |
| query.autoscaling.targetMemoryUtilizationPercentage |	Target memory utilization percentage to scale 50 |
| query.serviceAccount | Name of the Kubernetes service account to use | "" |

## Rule
|Name|Description| Default Value|
|----|-----------|--------------|
| rule.enabled | Enable component | false |
| rule.logLevel | Log level | info |
| rule.logFormat | Log format to use. Possible options: logfmt or json. | logfmt |
| rule.ruleLabels | Labels to be applied to all generated metrics (repeated). Similar to external labels for Prometheus, used to identify ruler and its blocks as unique source. | {} |
| rule.resendDelay | Minimum amount of time to wait before resending an alert to Alertmanager. | "" |
| rule.evalInterval | The default evaluation interval to use. | "" |
| rule.tsdbBlockDuration | Block duration for TSDB block. | "" |
| rule.tsdbRetention | Block retention time on local disk. | "" |
| rule.webRoutePrefix |Prefix for API and UI endpoints. This allows thanos UI to be served on a sub-path. This option is analogous to --web.route-prefix of Promethus. | "" |
| rule.webExternalPrefix |Static prefix for all HTML links and redirect URLs in the UI query web interface. Actual endpoints are still served on / or the web.route-prefix. This allows thanos UI to be served behind a reverse proxy that strips a URL sub-path | "" |
| rule.webPrefixHeader | Name of HTTP request header used for dynamic prefixing of UI links and redirects. This option is ignored if web.external-prefix argument is set. Security risk: enable this option only if a reverse proxy in front of thanos is resetting the header. The --web.prefix-header=X-Forwarded-Prefix option can be useful, for example, if Thanos UI is served via Traefik reverse proxy with PathPrefixStrip option enabled, which sends the stripped prefix value in X-Forwarded-Prefix header. This allows thanos UI to be served on a sub-path | "" |
| rule.queryDNSDiscovery | Enable DNS discovery for query insances | true |
| rule.alertmanagers |   # Alertmanager replica URLs to push firing alerts. Ruler claims success if push to at least one alertmanager from discovered succeeds. The scheme may be prefixed with 'dns+' or 'dnssrv+' to detect Alertmanager IPs  through respective DNS lookups. The port defaults to 9093 or the SRV record's value. The URL path is used as a prefix for the regular Alertmanager API path. | []] |
| rule.alertmanagersSendTimeout | Timeout for sending alerts to alertmanagert | "" |
| rule.alertQueryUrl |The external Thanos Query URL that would be set in all alerts 'Source' field | "" |
| rule.alertLabelDrop | Labels by name to drop before sending to alertmanager. This allows alert to be deduplicated on replica label (repeated). Similar Prometheus alert relabelling | [] |
| rule.ruleOverrideName | Override rules file with custom configmap | "" |
| rule.ruleFiles | See example in values.yaml | {}" |

## Compact

|Name|Description| Default Value|
|----|-----------|--------------|
| compact.enabled | Enable component | true |
| compact.replicaCount | Pod replica count | 1 |
| compact.logLevel | Log level | info |
| compact.logFormat | Log format to use. Possible options: logfmt or json. | logfmt |
| compact.serviceAccount | Name of the Kubernetes service account to use | "" |
| compact.consistencyDelay | Minimum age of fresh (non-compacted) blocks before they are being processed. Malformed blocks older than the maximum of consistency-delay and 30m0s will be removed.| 30m |
| compact.retentionResolutionRaw | How long to retain raw samples in bucket. 0d - disables this retention | 30d |
| compact.retentionResolution5m | How long to retain samples of resolution 1 (5 minutes) in bucket. 0d - disables this retention | 120d |
| compact.retentionResolution1h | How long to retain samples of resolution 2 (1 hour) in bucket. 0d - disables this retention | 1y |
| compact.blockSyncConcurrency | Number of goroutines to use when syncing block metadata from object storage. | 20 |
| compact.compactConcurrency | Number of goroutines to use when compacting groups. | 1 |
| compact.dataVolume.backend | Data volume for the compactor to store temporary data defaults to emptyDir. | {} |
| compact.persistentVolumeClaim | Create the specified persistentVolumeClaim in case persistentVolumeClaim is used for the dataVolume.backend above and needs to be created. | {} |

## Bucket

|Name|Description| Default Value|
|----|-----------|--------------|
| bucket.enabled | Enable component | true |
| bucket.replicaCount | Pod replica count | 1 |
| bucket.logLevel | Log level | info |
| bucket.logFormat | Log format to use. Possible options: logfmt or json. | logfmt |
| bucket.refresh | Refresh interval to download metadata from remote storage | 30m |
| bucket.timeout | Timeout to download metadata from remote storage | 5m |
| bucket.label | Prometheus label to use as timeline title | "" |
| bucket.http.port | Listening port for bucket web | 8080 |
| bucket.serviceAccount | Name of the Kubernetes service account to use | "" |
| bucket.podDisruptionBudget.enabled | Enabled and config podDisruptionBudget resource for this component | false |
| bucket.podDisruptionBudget.minAvailable | Minimum number of available query pods for PodDisruptionBudget | 1 |
| bucket.podDisruptionBudget.maxUnavailable | Maximum number of unavailable query pods for PodDisruptionBudget | [] |

## Sidecar

|Name|Description| Default Value|
|----|-----------|--------------|
| sidecar.enabled | NOTE: This is only the service references for the sidecar. | true |
| sidecar.selector | Pod label selector to match sidecar services on. | `{"app": "prometheus"}` |
