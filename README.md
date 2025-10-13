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

### Инструкция по поднятию кластера в minikube

1. `minikube start --cpus=10 --memory=32768 --driver=docker`
2. `minikube addons enable metrics-server`
3. `minikube addons enable ingress`
3. Склонировать репозиторий deploy и перейти в его папку
4. `kubectl apply -f ./namespaces`
5. Прописать корректные значения в манифесты секретов, `kubectl apply -f ./secrets`
6. `kubectl -f ./databases/postgres/cluster.yaml`, дождаться развертывания
7. `kubectl -f ./databases/postgres/managed-databases.yaml`, дождаться развертывания
8. `kubectl -f ./databases/postgres/pgbouncer.yaml`, дождаться развертывания
9. `kubectl apply -f ./rbac`
10. `kubectl apply -f ./serviceaccounts`
11. `kubectl apply -f ./vault`
12. `kubectl exec -n vault -it vault-0 -- /bin/sh`
13. `vault operator init`, записать полученные ключи и токен
14. Выполнить `vault operator unseal <UnsealKey>` 3 раза для 3 разных ключей
15. `vault status` (должно быть "Sealed: false")
16. `export VAULT_TOKEN=<Root Token>`
17. `vault secrets enable -path=secret -version=2 kv`
18. `vault kv put secret/api-gateway jwt_secret="<JWT Key HS256>"`
19. `vault kv put secret/authentication jwt_secret="<JWT Key HS256>" postgres_password="<пароль PostgreSQL из Step 5>"`
20. `vault auth enable kubernetes`
21. `vault write auth/kubernetes/config kubernetes_host="https://kubernetes.default.svc.cluster.local:443 token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"`
22. ```
    vault policy write api-gateway-policy - <<EOF
    path "secret/data/api-gateway" {
       capabilities = ["read"]
    }
    EOF
    ```
23. `vault write auth/kubernetes/role/api-gateway-role bound_service_account_names=default bound_service_account_namespaces=shadowchats policies=api-gateway-policy ttl=24h`
24. ```
    vault policy write authentication-policy - <<EOF
    path "secret/data/authentication" {
       capabilities = ["read"]
    }
    EOF
    ```
25. `vault write auth/kubernetes/role/authentication-role bound_service_account_names=default bound_service_account_namespaces=shadowchats policies=authentication-policy ttl=24h`
26. `exit`
27. `kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.27/releases/cnpg-1.27.0.yaml`
28. `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
29. `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml`
30. `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo`, записать полученный пароль
31. `kubectl -n argocd patch cm argocd-cmd-params-cm --type merge --patch-file ./argocd/cmd-params-cm-patch.json`
32. `kubectl -n argocd rollout restart deployment argocd-server`
33. `kubectl apply -f ./argocd/ingress.yaml`
34. `kubectl apply -f ./argocd/image-updater-config.yaml`
35. `kubectl apply -f ./argocd/root-app.yaml`
36. Зайти в ArgoCD UI: убедиться, что все приложения подтянулись; поменять пароль
37. Опционально, необходимо раскоментировать секции "resources" в манифестах "deployment.yaml" в папках микросервисов: `kubectl apply -f ./policies`

Примечания:
- Port-Forwarding: `kubectl port-forward -n ingress-nginx --address 0.0.0.0 svc/ingress-nginx-controller 8080:80 8443:443`; в отдельной консоли
