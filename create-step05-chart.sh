#!/usr/bin/env bash
set -e

rm -rf movie-chart
helm create movie-chart >/dev/null

rm -rf movie-chart/templates/*
mkdir -p movie-chart/templates

cat > movie-chart/Chart.yaml <<'YAML'
apiVersion: v2
name: movie-chart
description: Movie API Helm chart
type: application
version: 0.1.0
appVersion: "1.1"
YAML

cat > movie-chart/values.yaml <<'YAML'
replicaCount: 2

image:
  repository: idf775/movie-api
  tag: "1.1"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

config:
  PORT: "3000"

secret:
  mongoUri: "mongodb://{{ .Release.Name }}-mongo:27017/movies"

mongo:
  enabled: true
  image: mongo:7
  storage: 1Gi
  port: 27017

extraEnv:
  LOG_LEVEL: "info"
YAML

cat > movie-chart/values-prod.yaml <<'YAML'
replicaCount: 4

service:
  type: LoadBalancer

extraEnv:
  LOG_LEVEL: "warn"
YAML

cat > movie-chart/templates/_helpers.tpl <<'TPL'
{{- define "movie-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "movie-chart.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "movie-chart.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "movie-chart.labels" -}}
app: {{ include "movie-chart.name" . }}
release: {{ .Release.Name }}
chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "movie-chart.selectorLabels" -}}
app: {{ include "movie-chart.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "movie-chart.mongoName" -}}
{{- printf "%s-mongo" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
TPL

cat > movie-chart/templates/configmap.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "movie-chart.fullname" . }}-config
  labels:
    {{- include "movie-chart.labels" . | nindent 4 }}
data:
  {{- range $key, $val := .Values.config }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
YAML

cat > movie-chart/templates/secret.yaml <<'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "movie-chart.fullname" . }}-secret
  labels:
    {{- include "movie-chart.labels" . | nindent 4 }}
type: Opaque
stringData:
  MONGO_URI: {{ tpl .Values.secret.mongoUri . | quote }}
YAML

cat > movie-chart/templates/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "movie-chart.fullname" . }}
  labels:
    {{- include "movie-chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "movie-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "movie-chart.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: movie-api
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.targetPort }}
          {{- with .Values.extraEnv }}
          env:
            {{- range $key, $val := . }}
            - name: {{ $key }}
              value: {{ $val | quote }}
            {{- end }}
          {{- end }}
          envFrom:
            - configMapRef:
                name: {{ include "movie-chart.fullname" . }}-config
            - secretRef:
                name: {{ include "movie-chart.fullname" . }}-secret
          livenessProbe:
            httpGet:
              path: /health
              port: {{ .Values.service.targetPort }}
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: {{ .Values.service.targetPort }}
            initialDelaySeconds: 5
            periodSeconds: 5
YAML

cat > movie-chart/templates/service.yaml <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "movie-chart.fullname" . }}
  labels:
    {{- include "movie-chart.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  selector:
    {{- include "movie-chart.selectorLabels" . | nindent 4 }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
YAML

cat > movie-chart/templates/mongo-service.yaml <<'YAML'
{{- if .Values.mongo.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "movie-chart.mongoName" . }}
  labels:
    {{- include "movie-chart.labels" . | nindent 4 }}
    component: mongo
spec:
  clusterIP: None
  selector:
    {{- include "movie-chart.selectorLabels" . | nindent 4 }}
    component: mongo
  ports:
    - port: {{ .Values.mongo.port }}
      targetPort: 27017
{{- end }}
YAML

cat > movie-chart/templates/mongo-statefulset.yaml <<'YAML'
{{- if .Values.mongo.enabled }}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "movie-chart.mongoName" . }}
  labels:
    {{- include "movie-chart.labels" . | nindent 4 }}
    component: mongo
spec:
  serviceName: {{ include "movie-chart.mongoName" . }}
  replicas: 1
  selector:
    matchLabels:
      {{- include "movie-chart.selectorLabels" . | nindent 6 }}
      component: mongo
  template:
    metadata:
      labels:
        {{- include "movie-chart.selectorLabels" . | nindent 8 }}
        component: mongo
    spec:
      containers:
        - name: mongo
          image: {{ .Values.mongo.image }}
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-data
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongo-data
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: {{ .Values.mongo.storage }}
{{- end }}
YAML

cat > movie-chart/templates/NOTES.txt <<'TXT'
Movie API installed.

Port forward:
kubectl port-forward svc/{{ include "movie-chart.fullname" . }} 8080:{{ .Values.service.port }}

Health:
curl http://localhost:8080/health

{{- if .Values.mongo.enabled }}
MongoDB mode: in-cluster Mongo enabled.
Mongo service: {{ include "movie-chart.mongoName" . }}
{{- else }}
MongoDB mode: external Mongo.
{{- end }}
TXT

mkdir -p notes
cat > notes/step-05-helm-basic.md <<'MD'
# Step 05 - Helm basic chart

- created movie-chart
- added values.yaml and values-prod.yaml
- added helpers
- templated ConfigMap, Secret, Deployment, Service
- templated Mongo Service and StatefulSet
- added NOTES.txt
MD
