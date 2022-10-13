{{- define "jupiter.appversion" -}}
{{- $versionFile := .Files.Get "version.yaml" | fromYaml -}}
{{- $globalOverride := default nil .Values.global.OverrideAppVersion -}}
{{- $versionFileVersion := $versionFile.version -}}
{{- $override := default $versionFileVersion $globalOverride -}}
{{- default .Chart.AppVersion $override -}}
{{- end -}}