#!/bin/bash
set -e

echo "🚀 Shadowchats universal deployment"

# ──────────────────────────────
# Создаем namespace для Shadowchats
# ──────────────────────────────
kubectl apply -f namespace.yaml

# ──────────────────────────────
# Создаем секрет для доступа к Docker Registry
# и привязываем его к default ServiceAccount
# ──────────────────────────────
kubectl apply -f dockerhub-secret.yaml
kubectl apply -f default-sa.yaml

# ──────────────────────────────
# Проверка подключения к кластеру
# ──────────────────────────────
kubectl cluster-info

# ──────────────────────────────
# Установка CloudNativePG operator (если ещё не установлен)
# ──────────────────────────────
if ! kubectl get crd clusters.postgresql.cnpg.io >/dev/null 2>&1; then
    echo "Installing CloudNativePG operator..."
    kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.20/releases/cnpg-1.20.0.yaml
    # Ждем, пока оператор станет доступен
    kubectl wait --for=condition=Available deployment/cnpg-controller-manager -n cnpg-system --timeout=600s
fi

# ──────────────────────────────
# Применяем секреты для микросервисов
# ──────────────────────────────
kubectl apply -f authentication/secret.yaml
kubectl apply -f api-gateway/secret.yaml

# ──────────────────────────────
# Разворачиваем PostgreSQL (CloudNativePG)
# ──────────────────────────────
kubectl apply -f authentication/postgres.yaml
kubectl wait --for=condition=Ready cluster/authentication-postgres -n shadowchats --timeout=600s

# ──────────────────────────────
# Разворачиваем PgBouncer для подключения к БД
# ──────────────────────────────
kubectl apply -f authentication/pgbouncer.yaml
kubectl wait --for=condition=Ready pooler/authentication-pgbouncer-rw -n shadowchats --timeout=300s
kubectl wait --for=condition=Ready pooler/authentication-pgbouncer-ro -n shadowchats --timeout=300s

# ──────────────────────────────
# Разворачиваем Service + HPA для Authentication
# ──────────────────────────────
kubectl apply -f authentication/service.yaml
kubectl apply -f authentication/hpa.yaml

# ──────────────────────────────
# Разворачиваем Service + HPA + Ingress для API Gateway
# ──────────────────────────────
kubectl apply -f api-gateway/service.yaml
kubectl apply -f api-gateway/hpa.yaml
kubectl apply -f api-gateway/ingress.yaml

# ──────────────────────────────
# Ждем пока все деплойменты (будут применены позже в CI/CD) станут доступными
# ──────────────────────────────
for deploy in authentication api-gateway; do
    kubectl wait --for=condition=Available deployment/$deploy -n shadowchats --timeout=300s || true
done

echo "✅ Base environment ready!"
echo "Deployments will be applied via CI/CD pipelines."
