# Shadowchats.Deploy

Манифесты Kubernetes мессенджера **Shadowchats**.

## 📄 License

Shadowchats is free software licensed under the **GNU Affero General Public License v3.0**.

This means you can:
- ✅ Use the software for any purpose
- ✅ Study and modify the source code
- ✅ Distribute the software
- ✅ Distribute your modifications

**Important requirements:**
- 🔒 Any modifications must also be licensed under AGPL v3
- 📤 If you run a modified version on a server, you must provide source code to users
- 📝 You must preserve copyright notices and license information

See [LICENSE](LICENSE) for full details.

### Why AGPL v3?
We chose AGPL v3 to ensure that Shadowchats remains free and open source forever, even when used as a network service. This protects users' rights to access, study, and modify the software that handles their private communications.

## 📄 [COPYRIGHT](COPYRIGHT).

## 📧 Contact

For questions about licensing or to request source code:
- Email: lenya.dorovskoy@mail.ru
- GitHub repository: https://github.com/0ne290/Shadowchats.Deploy
- Author's GitHub: https://github.com/0ne290

## Деплой

```bash
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
kubectl apply -f Shadowchats.Authentication/secret-example.yaml
kubectl apply -f Shadowchats.ApiGateway/secret-example.yaml

# ──────────────────────────────
# Разворачиваем PostgreSQL (CloudNativePG)
# ──────────────────────────────
kubectl apply -f Shadowchats.Authentication/postgres.yaml
kubectl wait --for=condition=Ready cluster/authentication-postgres -n shadowchats --timeout=600s

# ──────────────────────────────
# Разворачиваем PgBouncer для подключения к БД
# ──────────────────────────────
kubectl apply -f Shadowchats.Authentication/pgbouncer.yaml
kubectl wait --for=condition=Ready pooler/authentication-pgbouncer-rw -n shadowchats --timeout=300s
kubectl wait --for=condition=Ready pooler/authentication-pgbouncer-ro -n shadowchats --timeout=300s

# ──────────────────────────────
# Разворачиваем микросервисы Authentication
# ──────────────────────────────
kubectl apply -f Shadowchats.Authentication/deployment.yaml
kubectl apply -f Shadowchats.Authentication/service.yaml
kubectl apply -f Shadowchats.Authentication/hpa.yaml

# ──────────────────────────────
# Разворачиваем API Gateway
# ──────────────────────────────
kubectl apply -f Shadowchats.ApiGateway/deployment.yaml
kubectl apply -f Shadowchats.ApiGateway/service.yaml
kubectl apply -f Shadowchats.ApiGateway/hpa.yaml
kubectl apply -f Shadowchats.ApiGateway/ingress.yaml

# ──────────────────────────────
# Ждем пока все деплойменты станут доступными
# ──────────────────────────────
for deploy in authentication api-gateway; do
    kubectl wait --for=condition=Available deployment/$deploy -n shadowchats --timeout=300s
done

echo "✅ Deployment completed!"
echo "Check status: kubectl get all -n shadowchats"
```
