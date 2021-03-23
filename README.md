# ITLab - Push-Notification Service
Сервис по отправке Push-уведомлений на мобильное устройство

Status | main | develop 
--- | --- | ---
Action | [![Deploy](https://github.com/RTUITLab/ITLab-PushNotificationService/actions/workflows/build-main.yml/badge.svg?branch=main)](https://github.com/RTUITLab/ITLab-PushNotificationService/actions/workflows/build-main.yml) | [![Test](https://github.com/RTUITLab/ITLab-PushNotificationService/actions/workflows/build-develop.yml/badge.svg?branch=develop)](https://github.com/RTUITLab/ITLab-PushNotificationService/actions/workflows/build-develop.yml)

## Запуск
### MacOS & Linux
#### MacOS
Для запуска проекта через терминал на MacOS потребуется установка [Vapor](https://docs.vapor.codes/4.0/install/macos/)

После установки достаточно в папке с проектом выполнить команду:
```bash
vapor run serve
```
Так же проект можно открыть и запустить с помощью `Xcode`

Сервер будет доступен по `127.0.0.1:8080`

#### Linux
Для запуска проекта через терминал в Linux потребуется установка [Vapor](https://docs.vapor.codes/4.0/install/linux/)

После установки достаточно в папке с проектом выполнить команду:
```bash
vapor run serve
```
Сервер будет доступен по `127.0.0.1:8080`

### Doker

```docker
docker-compose build
docker-compose up
```
Сервер будет доступен по `0.0.0.0:8080`

## Framework
Название | Ссылка
--- | ---
Vapor | https://github.com/vapor/vapor/
Vapor APNs | https://github.com/vapor/apns.git
Fluent | https://github.com/vapor/fluent
Fluent PostgreSQL | https://github.com/vapor/fluent-postgres-driver
