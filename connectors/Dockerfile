FROM confluentinc/cp-server-connect:7.8.1 AS base

USER root

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-gcs-source:2.6.10
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-gcs:10.2.1

USER appuser
