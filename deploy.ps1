# Script de despliegue completo - Backend + Frontend
# Este script despliega ambos: Backend en Cloud Run y Frontend en Firebase Hosting

$gcloudPath = "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
$projectId = "tallermovilapp-6efec"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DESPLIEGUE COMPLETO DEL PROYECTO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# PARTE 1: BACKEND (Cloud Run)
# ========================================
Write-Host "=== PARTE 1: DESPLIEGUE DEL BACKEND ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "Configurando proyecto: $projectId" -ForegroundColor Cyan
& $gcloudPath config set project $projectId

# Nombre de conexión FIJO
$instanceName = "tallermovilapp-6efec:us-central1:taller-movil-db"
Write-Host "Usando conexión Socket Unix: $instanceName" -ForegroundColor Cyan

$dbPass = Read-Host "Introduce la contraseña de la base de datos (usuario sergio)"

Write-Host ""
Write-Host "[1/2] Construyendo imagen Docker del backend..." -ForegroundColor Yellow
Set-Location backend
& $gcloudPath builds submit --tag "gcr.io/$projectId/taller-backend"

Write-Host ""
Write-Host "[2/2] Desplegando backend en Cloud Run..." -ForegroundColor Yellow
& $gcloudPath run deploy taller-backend `
  --image "gcr.io/$projectId/taller-backend" `
  --platform managed `
  --region us-central1 `
  --allow-unauthenticated `
  --memory 2Gi `
  --add-cloudsql-instances $instanceName `
  --set-env-vars "DB_HOST=/cloudsql/$instanceName,DB_USER=sergio,DB_PASSWORD=$dbPass,DB_NAME=taller-movil-db"

Set-Location ..

Write-Host ""
Write-Host "✅ Backend desplegado exitosamente" -ForegroundColor Green
Write-Host ""

# ========================================
# PARTE 2: FRONTEND (Firebase Hosting)
# ========================================
Write-Host "=== PARTE 2: DESPLIEGUE DEL FRONTEND ===" -ForegroundColor Yellow
Write-Host ""

# Verificar que Flutter esté instalado
$flutterCheck = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCheck) {
    Write-Host "❌ Error: Flutter no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "Por favor instala Flutter o agrégalo al PATH" -ForegroundColor Red
    exit 1
}

Write-Host "[1/3] Limpiando build anterior..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "[2/3] Construyendo aplicación Flutter para web..." -ForegroundColor Yellow
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: Falló la construcción de Flutter" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/3] Desplegando frontend en Firebase Hosting..." -ForegroundColor Yellow

# Verificar que Firebase CLI esté instalado
$firebaseCheck = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseCheck) {
    Write-Host "❌ Error: Firebase CLI no está instalado" -ForegroundColor Red
    Write-Host "Instala Firebase CLI con: npm install -g firebase-tools" -ForegroundColor Red
    exit 1
}

firebase deploy --only hosting

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: Falló el despliegue en Firebase" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ¡DESPLIEGUE COMPLETADO EXITOSAMENTE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend: Desplegado en Cloud Run" -ForegroundColor Cyan
Write-Host "Frontend: Desplegado en Firebase Hosting" -ForegroundColor Cyan
Write-Host ""
Write-Host "La funcionalidad de segmentación ya está disponible en la nube" -ForegroundColor Green

