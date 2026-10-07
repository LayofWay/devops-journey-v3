# DevOps Journey v3: Перерождение 🦅

# 🚀 DevOps Journey v3: От скриптов до GitOps

Этот репозиторий содержит полный цикл разработки и развертывания веб-приложения (Flask + PostgreSQL) с использованием современных DevOps-практик. Проект создан с нуля как демонстрация навыков автоматизации, контейнеризации и оркестрации.

## 🛠️ Технологический стек
- **IaC:** Ansible, Ansible Vault
- **Контейнеризация:** Docker, Docker Compose
- **Оркестрация:** Kubernetes (Kind), Deployments, Services, Ingress, PVC, Secrets, ConfigMaps
- **CI/CD & GitOps:** GitHub Actions, Self-hosted Runner

## 🏗️ Архитектура проекта
Проект разделен на логические этапы:
1. `stage-01-ansible`: Автоматизированная установка и настройка PostgreSQL с безопасным хранением паролей (Vault).
2. `stage-02-docker`: Контейнеризация Flask-приложения, управление переменными окружения (.env) и базовый CI-пайплайн.
3. `stage-03-kubernetes`: Полный перенос стека в K8s. Включает:
   - Отказоустойчивость (3 реплики приложения).
   - Постоянное хранение данных БД (PersistentVolumeClaim).
   - Ограничение ресурсов (Requests/Limits) для защиты кластера.
   - Маршрутизацию трафика через NGINX Ingress Controller.
   - **GitOps:** Автоматическая сборка и деплой новых версий при `git push` через локальный Self-hosted Runner.

## 🚀 Как запустить локально (Kubernetes)

### Предварительные требования
- Установленные `docker`, `kind`, `kubectl`
- Локальный кластер с именем `devops-lab`

### Пошаговый запуск
1. Загрузите образ приложения в кластер:
   ```bash
   cd stage-02-docker/app
   docker build -t devops-app:v1 .
   kind load docker-image devops-app:v1 --name devops-lab

2. Примените манифесты Kubernetes (включая секреты, конфиги и ingress):
   cd ../../stage-03-kubernetes/manifests
   kubectl apply -f .

3. Пробросьте порт для локального доступа:
   kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80

4. Откройте в браузере или через curl: http://127.0.0.1:8080/
```

🔐 Безопасность
Пароли не хранятся в открытом виде в коде или Dockerfile.
Используется ansible-vault для шифрования секретов на этапе IaC.
В Kubernetes секреты управляются через объект Secret, а конфигурации вынесены в ConfigMap.
