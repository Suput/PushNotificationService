# ITLab - Push-Notification Service
Сервис по отправке Push-уведомлений на мобильное устройство

Status | main | develop 
--- | --- | ---
Action | [![Build Status](https://dev.azure.com/rtuitlab/RTU%20IT%20Lab/_apis/build/status/ITLab/ITLab-PushNotificationService?branchName=main)](https://dev.azure.com/rtuitlab/RTU%20IT%20Lab/_build/latest?definitionId=164&branchName=main) | [![Build Status](https://dev.azure.com/rtuitlab/RTU%20IT%20Lab/_apis/build/status/ITLab/ITLab-PushNotificationService?branchName=develop&stageName=Build%20image&jobName=Build)](https://dev.azure.com/rtuitlab/RTU%20IT%20Lab/_build/latest?definitionId=164&branchName=develop)
## Конфигурация
Для работы с сервисом вам понадобиться конфигруационный файл `settings.json`, `FCM.json`, `apns.crt.pem` и `apns.key.pem`

**settings.json**:
```json
{
    "apns": {
        "keyPass": "<YOUR SECRET KEY PASSWORD>",
        "topic": "<Build identifier of your project where notifications are sent to>"
    },
    
    "jwkURL": "<Optional - Your JWK link if you want to work with 3rd party JWT>",

    "database": {
        "hostname": "localhost",
        "login": "postgres",
        "password": "postgres",
        "databaseName": "notify"
    },

    "redis": {
        "hostname": "localhost"
    }
}

```

**FCM.json**:

Данный файл с приватным ключом нужно сгенерировать на сайте [Firebase](https://console.firebase.google.com/)

Инструкция по генерации файла `FCM.json`: [тык.](https://firebase.google.com/docs/cloud-messaging/auth-server?authuser=0#provide-credentials-manually)

**apns.crt.pem и apns.key.pem**:

Данный файл нужно сгенерировать на сайте [Apple Developers](https://developer.apple.com/)

Инструкция по генерации файла `apns.crt.pem` и `apns.key.pem`: [тык.](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns)

Конфигурационный файл `settins.json` и `FCM.json` нужно разместить по пути `/Private/json/`. Файл `apns.crt.pem` и `apns.key.pem` - `/Private/APNs/`

## Запуск

### Запуск тестирования
> For linux
```bash
./start_test.sh up --build
```

> For windows
```bash
.\start_test.ps1 up --build
```
### MacOS & Linux
#### MacOS
Для запуска проекта через терминал на MacOS потребуется установка [Vapor](https://docs.vapor.codes/4.0/install/macos/)

После установки достаточно в папке с проектом выполнить команду:
```bash
vapor run serve
```
Так же проект можно открыть и запустить с помощью `Xcode`

При первом запуске у Вас может возникнуть ошибка:
```bash
[ WARNING ] No custom working directory set for this scheme, using /path/to/DerivedData/project-abcdef/Build/
```

Для решение данной проблемы воспользуйте [данной ссылкой](https://docs.vapor.codes/4.0/xcode/#custom-working-directory)

Сервер будет доступен по `127.0.0.1:8080`


#### Linux
Для запуска проекта через терминал в Linux потребуется установка [Vapor](https://docs.vapor.codes/4.0/install/linux/)

После установки достаточно в папке с проектом выполнить команду:
```bash
vapor run serve
```
Сервер будет доступен по `127.0.0.1:8080`

### Docker

```docker
docker-compose build
docker-compose up
```

При использовании `docker-compose` в файле `settings.json` может присутсвовать только поля `apns` и `jwkURL`

Сервер будет доступен по `0.0.0.0:8080`

## Плагины для устройств

Устройство | Ссылка
--- | ---
 iOS| https://github.com/RTUITLab/PushNotification-iOS
 Android | Coming soon
 Flutter | Coming soon

## Framework
Название | Ссылка
--- | ---
Vapor | https://github.com/vapor/vapor/
APNs | https://github.com/vapor/apns
FCM (Firebase) | https://github.com/MihaelIsaev/FCM
Fluent | https://github.com/vapor/fluent
Fluent PostgreSQL | https://github.com/vapor/fluent-postgres-driver
JWT | https://github.com/vapor/jwt
Redis | https://github.com/vapor/redis
Queues | https://github.com/vapor/queues
