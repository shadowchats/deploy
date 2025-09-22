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

### Первый

1. `git clone https://github.com/shadowchats/Deploy.git && cd Deploy`.
2. Переименуй `*-secret-example.yaml` → `secret.yaml` и впиши правильные значения.
3. Укажи креды в `dockerhub-secret.yaml`.
4. Запусти: `./deploy.sh`.
5. Включи Ingress и HPA:
   - Minikube: `minikube addons enable ingress`
   - Kubernetes: `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml`
   - Потом: `kubectl apply -f ingress-nginx-hpa.yaml`
6. Выполни конвейеры `build-and-push.yaml` в репозиториях микросервисов и конвейер `deploy-to-local-minikube.yaml` в этом репозитории для каждого микросервиса.
7. Проверка: `kubectl get all -n shadowchats`.

### После первого

Повторять пункт 5.
