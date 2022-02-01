# klint 🧹

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

A consolidated suite of kubernetes tools in a single container.

This is a portable solution to validate ☸️ manifests anywhere with a container runtime; local machine, CI, etc.

## Reminders 🎗

- The container is set with the permissions `nobody:nobody`
- The container's **workspace** is set to `/src`
- The container doesn't have `curl`, but it has `wget`
- Any vulnerabilities are not my own; see tools 🔧

## Tools 🔧

This swiss army knife stands on the shoulders of giants:

| Name                                                      | Version   | License                                                                        | Description                                                                           |
| --------------------------------------------------------- | --------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| [helm](https://github.com/helm/helm)                      | `v3.7`    | [Apache 2.0](https://github.com/helm/helm/blob/main/LICENSE)                   | The Kubernetes Package Manager                                                        |
| [kubectl](https://github.com/kubernetes/kubectl)          | `v1.23.3` | [Apache 2.0](https://github.com/kubernetes/kubectl/blob/master/LICENSE)        | The designated kubernetes CLI client                                                  |
| [kubesec](https://github.com/controlplaneio/kubesec)      | `v2.11.4` | [Apache 2.0](https://github.com/controlplaneio/kubesec/blob/master/LICENSE)    | Security risk analysis for Kubernetes resources                                       |
| [kubeval](https://github.com/instrumenta/kubeval)         | `v0.15.0` | [Apache 2.0](https://github.com/instrumenta/kubeval/blob/master/LICENSE)       | Validate your Kubernetes configuration files, supports multiple Kubernetes versions   |
| [kube-score](https://github.com/zegl/kube-score)          | `v1.13.0` | [Apache 2.0](https://github.com/zegl/kube-score/blob/master/LICENSE)           | Kubernetes object analysis with recommendations for improved reliability and security |
| [kustomize](https://github.com/kubernetes-sigs/kustomize) | `v4.4.1`  | [Apache 2.0](https://github.com/kubernetes-sigs/kustomize/blob/master/LICENSE) | Customization of kubernetes YAML configurations                                       |

## Usage 🐳

For local usage... first spin up the container

```BASH
$ docker run --rm -it -v `pwd`:/src derekahn/klint
```

### Kubescore

##### Example Usage

```bash
/src $ kube-score score *.yaml
```

##### Example Output

```bsh
apps/v1/Deployment my-app in awesome                                    💥
  [CRITICAL] Pod Probes
    · Container has the same readiness and liveness probe
        Using the same probe for liveness and readiness is very likely dangerous. Generally it's better to avoid
        the livenessProbe than re-using the readinessProbe.
        More information: https://github.com/zegl/kube-score/blob/master/README_PROBES.md
  [CRITICAL] Container Resources
    · scala-sample -> CPU limit is not set
        Resource limits are recommended to avoid resource DDOS. Set resources.limits.cpu
    · scala-sample -> Memory limit is not set
        Resource limits are recommended to avoid resource DDOS. Set resources.limits.memory
    · scala-sample -> CPU request is not set
        Resource requests are recommended to make sure that the application can start and run without crashing.
        Set resources.requests.cpu
    · scala-sample -> Memory request is not set
        Resource requests are recommended to make sure that the application can start and run without crashing.
        Set resources.requests.memory
  [CRITICAL] Container Image Tag
    · scala-sample -> Image with latest tag
        Using a fixed tag is recommended to avoid accidental upgrades
  [CRITICAL] Pod NetworkPolicy
    · The pod does not have a matching NetworkPolicy
        Create a NetworkPolicy that targets this pod to control who/what can communicate with this pod. Note, this
        feature needs to be supported by the CNI implementation used in the Kubernetes cluster to have an effect.
  [CRITICAL] Deployment has PodDisruptionBudget
    · No matching PodDisruptionBudget was found
        It's recommended to define a PodDisruptionBudget to avoid unexpected downtime during Kubernetes
        maintenance operations, such as when draining a node.
  [WARNING] Deployment has host PodAntiAffinity
    · Deployment does not have a host podAntiAffinity set
        It's recommended to set a podAntiAffinity that stops multiple pods from a deployment from being scheduled
        on the same node. This increases availability in case the node becomes unavailable.
v1/Service my-app in awesome                                        ✅
```

### Kubeval

##### Example Usage

```bash
/src $ kube-score score *.yaml
```

##### Example Output

```bash
PASS - my-app-deply.yaml contains a valid Deployment (awesome.my-app)
PASS - my-app-svc.yaml contains a valid Service (awesome.my-app-svc)
```

### Kubesec

##### Example Usage

```bash
/src $ kubesec scan my-app-deploy.yaml
```

##### Example Output

```bash
[
  {
    "object": "Deployment/my-app.awesome",
    "valid": true,
    "fileName": "my-app-deploy.yaml",
    "message": "Passed with a score of 5 points",
    "score": 5,
    "scoring": {
      "passed": [
        {
          "id": "CapDropAny",
          "selector": "containers[] .securityContext .capabilities .drop",
          "reason": "Reducing kernel capabilities available to a container limits its attack surface",
          "points": 1
        },
        {
          "id": "CapDropAll",
          "selector": "containers[] .securityContext .capabilities .drop | index(\"ALL\")",
          "reason": "Drop all capabilities and add only those required to reduce syscall attack surface",
          "points": 1
        },
        {
          "id": "ReadOnlyRootFilesystem",
          "selector": "containers[] .securityContext .readOnlyRootFilesystem == true",
          "reason": "An immutable root filesystem can prevent malicious binaries being added to PATH and increase attack cost",
          "points": 1
        },
        {
          "id": "RunAsNonRoot",
          "selector": "containers[] .securityContext .runAsNonRoot == true",
          "reason": "Force the running image to run as a non-root user to ensure least privilege",
          "points": 1
        },
        {
          "id": "RunAsUser",
          "selector": "containers[] .securityContext .runAsUser -gt 10000",
          "reason": "Run as a high-UID user to avoid conflicts with the host's user table",
          "points": 1
        }
      ],
      "advise": [
        {
          "id": "ApparmorAny",
          "selector": ".metadata .annotations .\"container.apparmor.security.beta.kubernetes.io/nginx\"",
          "reason": "Well defined AppArmor policies may provide greater protection from unknown threats. WARNING: NOT PRODUCTION READY",
          "points": 3
        },
        {
          "id": "ServiceAccountName",
          "selector": ".spec .serviceAccountName",
          "reason": "Service accounts restrict Kubernetes API access and should be configured with least privilege",
          "points": 3
        },
        {
          "id": "SeccompAny",
          "selector": ".metadata .annotations .\"container.seccomp.security.alpha.kubernetes.io/pod\"",
          "reason": "Seccomp profiles set minimum privilege and secure against unknown threats",
          "points": 1
        },
      ]
    }
  }
]
```

### Kustomize

```
/src $ kustomize build overlays/development/
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    kube-score/ignore: pod-networkpolicy,deployment-has-host-podantiaffinity,container-security-context,deployment-has-poddisruptionbudget
  name: awesome
---
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    kube-score/ignore: pod-networkpolicy,deployment-has-host-podantiaffinity,container-security-context,deployment-has-poddisruptionbudget
  labels:
    app: my-app
  name: my-app
  namespace: awesome
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      annotations:
        kube-score/ignore: pod-networkpolicy,deployment-has-host-podantiaffinity,container-security-context,deployment-has-poddisruptionbudget
      labels:
        app: my-app
    spec:
      containers:
      - image: k8s:5000/my-app
        imagePullPolicy: Always
        name: my-app
        ports:
        - containerPort: 5000
        resources:
          limits:
            cpu: 1
            memory: 2048Mi
          requests:
            cpu: 1
            memory: 512Mi
```

## Continuous Integration

These are just simple examples of plugging this into your CI

### Github Actions

```yaml
jobs:
  container:
    runs-on: ubuntu-latest
    container: derekahn/klint:latest
    steps:
      - run: |
          kubeval *.yaml
        name: Run in container
```

### Jenkins example using Docker agents

`Jenkinsfile`

```jenkinsfile
pipeline {
  agent {
    docker { image 'derekahn/klint:latest' }
  }

  stages {
    stage('lint') {
      steps {
        sh 'kubeval *.yaml'
      }
    }
    stage('validate') {
      steps {
        sh 'kube-score score *.yaml'
      }
    }
    stage('security scan') {
      steps {
        sh 'kubeval *.yaml'
      }
    }
  }
}
```

### Drone

`.drone.yml`

```yaml
kind: pipeline
name: k8s validations

steps:
  - name: lint
    image: derekahn/klint:latest
    commands:
      - kubeval score *.yaml
  - name: validate
    image: derekahn/klint:latest
    commands:
      - kube-score score *.yaml
  - name: scan
    image: derekahn/klint:latest
    commands:
      - kubesec scan *.yaml
```

### Circle-CI

`.circleci/config.yml`

```yaml
version: 2.0
jobs:
  build:
    docker:
      - image: derekahn/klint:latest
```
