# Strimzi Kafka
- Requirements:
  - Prep your kafka configuration for your yaml.

- Processes:
  - Kafka Producer > Kafka Broker > Kafka consumer > Knative? 

- Reference:
  - [Strimzi Documentation](https://strimzi.io/docs/operators/latest/deploying#deploying-cluster-operator-helm-chart-str)
  - [Kafka Documentation](https://kafka.apache.org/documentation/)
  - [Strimzi Kafka Cluster Example](https://github.com/utkarsh-devops/strimzi-kafka-operator/blob/main/examples/systems-kafka/kafka.yaml)


## Install Strimzi Kafka (HELM)

```sh
helm repo add strimzi https://strimzi.io/charts --force-update
helm upgrade -i strimzi-kafka-operator strimzi/strimzi-kafka-operator --create-namespace --namespace kafka --version 0.40.0
```

## Install Kafka Cluster with Strimzi Operator

```sh
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: systems-kafka-user
  namespace: kafka
  labels:
    strimzi.io/cluster: systems-kafka-cluster
spec:
  authentication:
    type: scram-sha-512
  authorization:
    type: simple
    acls:
      # Example ACL rules for consuming from my-topic using consumer group my-group
      - resource:
          type: topic
          name: systems-topic
          patternType: literal
        operations:
          - Describe
          - Read
        host: "*"
      - resource:
          type: group
          name: systems-group
          patternType: literal
        operations:
          - Read
        host: "*"
      # Example ACL rules for producing to topic my-topic
      - resource:
          type: topic
          name: systems-topic
          patternType: literal
        operations:
          - Create
          - Describe
          - Write
        host: "*"
---
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
  namespace: kafka
spec:
  kafka:
    version: 3.7.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
        authentication:
          type: scram-sha-512
    authorization:
      type: simple
    readinessProbe:
      initialDelaySeconds: 15
      timeoutSeconds: 5
    livenessProbe:
      initialDelaySeconds: 15
      timeoutSeconds: 5
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      default.replication.factor: 3
      min.insync.replicas: 2
      inter.broker.protocol.version: '3.7'
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 10Gi
        deleteClaim: true
    # metricsConfig:
    #   type: jmxPrometheusExporter
    #   valueFrom:
    #     configMapKeyRef:
    #       name: kafka-metrics
    #       key: kafka-metrics-config.yml
  zookeeper:
    replicas: 3
    readinessProbe:
      initialDelaySeconds: 15
      timeoutSeconds: 5
    livenessProbe:
      initialDelaySeconds: 15
      timeoutSeconds: 5
    storage:
      type: persistent-claim
      size: 10Gi
      deleteClaim: true
    # metricsConfig:
    #   type: jmxPrometheusExporter
    #   valueFrom:
    #     configMapKeyRef:
    #       name: kafka-metrics
    #       key: zookeeper-metrics-config.yml
  entityOperator:
    topicOperator: {}
    userOperator: {}
  kafkaExporter:
    topicRegex: ".*"
    groupRegex: ".*"
```

