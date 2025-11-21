# Script de despliegue automático - SOCKET UNIX (SEGURO)
$gcloudPath = "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
$projectId = "tallermovilapp-6efec"

Write-Host "=== Configurando Proyecto: $projectId ===" -ForegroundColor Cyan
& $gcloudPath config set project $projectId

# Nombre de conexión FIJO (para evitar errores)
$instanceName = "tallermovilapp-6efec:us-central1:taller-movil-db"
Write-Host "`nUsando conexión Socket Unix: $instanceName" -ForegroundColor Cyan

$dbPass = Read-Host "Introduce la contraseña de la base de datos (usuario sergio)"

Write-Host "`n[1/2] Construyendo imagen..." -ForegroundColor Yellow
& $gcloudPath builds submit --tag "gcr.io/$projectId/taller-backend"

Write-Host "`n[2/2] Desplegando en Cloud Run..." -ForegroundColor Yellow
& $gcloudPath run deploy taller-backend `
  --image "gcr.io/$projectId/taller-backend" `
  --platform managed `
  --region us-central1 `
  --allow-unauthenticated `
  --memory 2Gi `
  --add-cloudsql-instances $instanceName `
  --set-env-vars "DB_HOST=/cloudsql/$instanceName,DB_USER=sergio,DB_PASSWORD=$dbPass,DB_NAME=taller-movil-db"

Write-Host "`n=== ¡Proceso Finalizado! ===" -ForegroundColor Green