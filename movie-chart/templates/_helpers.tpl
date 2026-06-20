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

