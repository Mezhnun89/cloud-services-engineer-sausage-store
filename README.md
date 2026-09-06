# «Сосисочная» — финальный проект второго семестра

Учебный проект Межнуна Оруджалиева. Основа: [шаблон Практикума](https://github.com/yandex-praktikum/cloud-services-engineer-sausage-store-project-sem2).

## Состояние

Проект развёрнут в учебном Kubernetes: [открыть магазин](https://front-mezhnun.2sem.students-projects.ru).

- [CI приложения](https://github.com/Mezhnun89/cloud-services-engineer-sausage-store/actions/runs/34055252580): три образа, 4 Java-теста, Go-тесты, Helm lint, миграции и сохранение заказа после пересоздания PostgreSQL Pod в kind.
- [Публикация и деплой](https://github.com/Mezhnun89/cloud-services-engineer-sausage-store/actions/runs/34056638324): образы опубликованы в Docker Hub; Helm-чарт опубликован в Nexus и установлен именно оттуда, release `sausage-store` в статусе `deployed`.
- [Проверка учебного кластера](https://github.com/Mezhnun89/cloud-services-engineer-sausage-store/actions/runs/34056994565): HTTPS, шесть товаров, заказ на 640 ₽, четыре успешные миграции, HPA с метриками CPU и VPA с рекомендациями.
- [Проверка MongoDB](https://github.com/Mezhnun89/cloud-services-engineer-sausage-store/actions/runs/34057076100): коллекция `sausage-store.reports` содержит сохранённые отчёты.
- В браузере проверены добавление и удаление товара, сумма корзины и сообщение «Заказ успешно оформлен».

Оба PVC имеют статус Bound и размер 2Gi. Доступ к учебному namespace ограничен 21 днём с момента выдачи 6 сентября 2026 года. Vault — дополнительное задание, не реализовано.

## Архитектура

Ingress TLS → frontend (Angular + Nginx) → backend (Java 17 / Spring Boot) → PostgreSQL и MongoDB.
Отдельный Go backend-report сохраняет отчёты в MongoDB.

- `backend/`: multi-stage образ, непривилегированный пользователь, Flyway при старте Spring Boot. Hibernate проверяет схему, но не меняет её.
- `frontend/`: production-сборка Angular, Nginx от UID 101, проксирование `/api/` в backend через ConfigMap.
- `backend-report/`: исправлены имя стадии, путь бинарного файла; сборка выполняет Go-тесты.
- `sausage-store-chart/`: родительский Helm-чарт, сабчарты backend, backend-report, frontend, infra.
- `scripts/`: проверка квот, проверка приложения в kind, генерация приватного Secret.

## Миграции

Миграции перенесены из [моего DBOps-проекта](https://github.com/Mezhnun89/cloud-services-engineer-dbops-project/tree/main/migrations).

| Миграция | Результат |
|---|---|
| V001 | Исходная схема магазина |
| V002 | Нормализация, первичные и внешние ключи |
| V003 | 6 товаров и **10 000** заказов/позиций; синхронизация identity-последовательностей |
| V004 | Индексы по дате заказа и внешним ключам |

В PostgreSQL и MongoDB используются StatefulSet и PVC по 2 GiB. MongoDB создаёт пользователя `reports` с ролью readWrite и коллекцию через init-скрипт при первом запуске пустого PVC. Повторная установка поверх существующего PVC не меняет пароль автоматически.

## Квоты и обновления

Backend: RollingUpdate, maxSurge=1, maxUnavailable=0; backend-report: Recreate.
VPA backend работает в режиме `Off` (рекомендации CPU/памяти); HPA backend-report: 1–3 реплики, CPU 75%.
Backend имеет startup/readiness/liveness probes `/actuator/health`.

Худший предусмотренный случай — 2 backend, 2 frontend, 3 report и 2 БД:

| Ресурс | Сумма | Квота |
|---|---:|---:|
| CPU requests | 1050m | 2000m |
| CPU limits | 2950m | 3000m |
| Memory requests | 992Mi | 1000Mi |
| Memory limits | 2472Mi | 2500Mi |
| Pods | 9 | 10 |
| Services | 5 | 5 |
| PVC / storage | 2 / 4Gi | 4 / 5Gi |

Для дополнительных отладочных pod может не хватить свободной квоты памяти. Перед изменением реплик/ресурсов проверяйте суммарный бюджет. История Helm ограничена тремя ревизиями из-за квоты Secrets.

## Подготовка развёртывания

1. В уроке получения namespace скачать kubeconfig. Срок доступа — 21 день. **Не коммитить этот файл**.
2. В учебном [Nexus](https://nexus.cloud-services-engineer.education-services.ru) создать `helm (hosted)`, например `mezhnun-sausage`, с `Deployment policy: Allow redeploy`.
3. Создать файл с паролями один раз:
   ```bash
   python3 scripts/create-db-secret.py ../sausage-db-secret.json
   ```
   Хранить его приватно. Не генерировать новые пароли поверх существующих PVC.
4. Заполнить GitHub Actions Secrets репозитория:

| Secret | Содержимое |
|---|---|
| DOCKER_USER | `mezhnun` |
| DOCKER_PASSWORD | Docker Hub PAT с правом записи образов |
| KUBE_CONFIG | Полный kubeconfig из тренажёра, обычный YAML |
| DB_SECRET_JSON | Содержимое сгенерированного приватного JSON |
| NEXUS_HELM_REPO | URL созданного Hosted Helm репозитория |
| NEXUS_HELM_REPO_USER | Учебный пользователь Nexus для API |
| NEXUS_HELM_REPO_PASSWORD | Его пароль/токен для API |

Секреты предыдущего проекта не наследуются новым репозиторием. Пароли/токены не нужно присылать в чат или включать в README.

5. Установить repository variable `CLUSTER_ACCESS_ENABLED=true`, затем запустить `Verify Sausage Store`. Проверка доступа к namespace включается только после настройки kubeconfig.
6. Убедиться, что `frontend.fqdn` в values.yaml свободен/допустим в учебном кластере. Сейчас задан `front-mezhnun.2sem.students-projects.ru`; TLS Secret: `2sem-students-projects-wildcard-secret`.
7. Запустить `Sausage Store Deploy` вручную. Workflow собирает и публикует три образа с тегом commit SHA, упаковывает Helm-чарт в Nexus и устанавливает **версию из Nexus**, используя тот же SHA образов. Чувствительные данные применяются отдельным Secret, не через Helm values.

```bash
helm lint sausage-store-chart
kubectl get pods,svc,ingress,hpa,vpa
kubectl describe resourcequota
helm list
kubectl describe vpa sausage-store-backend
kubectl describe hpa sausage-store-backend-report
```

Проверить `STATUS: deployed`, VPA `RecommendationProvided`, HPA с реальными метриками и оформление заказа через HTTPS. Лишь после этого сдавать ссылку на репозиторий.

## Проверки

`Verify Sausage Store` собирает все три образа, выполняет Java/Go тесты и устанавливает чарт в временный kind-кластер. Скрипт проверяет выдачу frontend, каталог из шести товаров, создание заказа после seed (id > 10000), итоговую сумму и сохранение заказа после пересоздания PostgreSQL pod. Артефакт `sausage-verification` содержит результаты и диагностику.

В kind VPA/HPA выключены, поскольку этот тест проверяет приложение и хранилище. Их работу необходимо отдельно подтвердить в учебном кластере; успешный kind-тест не считается подтверждением облачного деплоя.

## Ограничения учебного шаблона

Angular 6 и Spring Boot 2.x унаследованы от курса. Обновлён Java runtime и исправлена production-сборка, но полноценное обновление всех зависимостей и аудит безопасности здесь не заявляются. Builder использует `--openssl-legacy-provider` только для старого webpack. `--ignore-scripts` пропускает установочные скрипты старых npm-пакетов; проект использует CSS, а не нативный node-sass.

Дополнительное задание с Vault пока не выполнено. Пароли вынесены в Kubernetes Secret; это не эквивалент интеграции с Vault. Источник отчётов Go-сервиса — внешний учебный API из исходного шаблона; его доступность проверяется при практическом запуске.

## Доступ к учебному кластеру

[Проверка доступа №34055842027](https://github.com/Mezhnun89/cloud-services-engineer-sausage-store/actions/runs/34055842027) успешна. Все необходимые GitHub Actions Secrets настроены; значения не хранятся в репозитории. Для повторного деплоя используется `Sausage Store Deploy`; для проверки — `Verify training deployment` и `Verify persisted reports`.
