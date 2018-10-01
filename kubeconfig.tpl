apiVersion: v1
kind: Config
preferences: {}

clusters:
- cluster:
    server: ${server}
    certificate-authority-data: ${certificate_authority_data}
  name: ${cluster_name}

contexts:
- context:
    cluster: ${cluster_name}
    user: ${cluster_name}
  name: ${cluster_name}

current-context: ${cluster_name}

users:
- name: ${cluster_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${cluster_name}"
