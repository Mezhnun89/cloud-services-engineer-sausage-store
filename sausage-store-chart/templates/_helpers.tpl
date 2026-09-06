{{- define "sausage.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ .Values.global.imageTag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/component: {{ .Chart.Name | quote }}
app.kubernetes.io/part-of: sausage-store
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
env: {{ .Values.global.environment | quote }}
{{- end }}
