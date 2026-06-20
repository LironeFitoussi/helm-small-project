from pathlib import Path

# remove local mongo templates - Bitnami subchart replaces them
Path("movie-chart/templates/mongo-service.yaml").exists() and Path("movie-chart/templates/mongo-service.yaml").unlink()
Path("movie-chart/templates/mongo-statefulset.yaml").exists() and Path("movie-chart/templates/mongo-statefulset.yaml").unlink()

# Chart.yaml with dependency
Path("movie-chart/Chart.yaml").write_text("""apiVersion: v2
name: movie-chart
description: Movie API Helm chart
type: application
version: 0.2.0
appVersion: "1.1"

dependencies:
  - name: mongodb
    version: "15.6.26"
    repository: "https://charts.bitnami.com/bitnami"
    condition: mongodb.enabled
""")

# values.yaml - move from local mongo to mongodb subchart values
values = Path("movie-chart/values.yaml")
text = values.read_text()

text = text.replace(
    'mongoUri: "mongodb://{{ .Release.Name }}-mongo:27017/movies"',
    'mongoUri: "mongodb://root:secretpass@{{ .Release.Name }}-mongodb:27017/movies?authSource=admin"'
)

start = text.find("\nmongo:\n")
if start != -1:
    end = text.find("\nextraEnv:", start)
    extra = text[end:] if end != -1 else ""

    text = text[:start] + """
mongodb:
  enabled: true
  architecture: standalone
  auth:
    rootPassword: "secretpass"
  persistence:
    enabled: true
    size: 1Gi
  image:
    registry: docker.io
    repository: bitnamilegacy/mongodb
  global:
    security:
      allowInsecureImages: true
""" + extra

text = text.replace("mongo.enabled", "mongodb.enabled")
values.write_text(text)

# NOTES.txt - use mongodb condition and service name
notes = Path("movie-chart/templates/NOTES.txt")
n = notes.read_text()
n = n.replace("{{- if .Values.mongo.enabled }}", "{{- if .Values.mongodb.enabled }}")
n = n.replace(
    'Mongo service: {{ include "movie-chart.mongoName" . }}',
    "Mongo service: {{ .Release.Name }}-mongodb"
)
notes.write_text(n)

# helpers - remove local mongo helper
helpers = Path("movie-chart/templates/_helpers.tpl")
h = helpers.read_text()
h = h.replace(
    '{{- define "movie-chart.mongoName" -}}\n{{- printf "%s-mongo" .Release.Name | trunc 63 | trimSuffix "-" -}}\n{{- end -}}\n',
    ""
)
helpers.write_text(h)
