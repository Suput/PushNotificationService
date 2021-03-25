# ITLab - Push-Notification Service
Сервис по отправке Push-уведомлений на мобильное устройство

Status | main | develop 
--- | --- | ---
Action | [![Deploy](https://github.com/RTUITLab/ITLab-PushNotificationService/actions/workflows/build-main.yml/badge.svg?branch=main)](https://github.com/RTUITLab/ITLab-PushNotificationService/actions/workflows/build-main.yml) | [![Test](https://github.com/RTUITLab/ITLab-PushNotificationService/actions/workflows/build-develop.yml/badge.svg?branch=develop)](https://github.com/RTUITLab/ITLab-PushNotificationService/actions/workflows/build-develop.yml)

## Конфигурация
Для работы с сервисом вам понадобиться конфигруационный файл `settings.json` и `APNs.p8`

**settings.json**:
```json
{
    "apns": {
        "keyIdentifier": "<YOUR key identifier>",
        "teamIdentifier": "<YOUR team identifier>",
        "topic": "<Build identifier of your project where notifications are sent to>"
    },
    
    "database": {
        "hostname": "localhost",
        "login": "postgres",
        "password": "postgres",
        "databaseName": "notify"
    }
}

```

**APNs.p8**
Данный файл нужно сгенерировать на сайте [Apple Developers](https://developer.apple.com/)

Инструкция по генерации файла `APNs.p8`: [тык.](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns)

### Debug пути
Конфигурационный файл `settins.json` нужно разместить по пути `/Private/json/`. Файл `APNs.p8` - `/Private/`

### Production пути
***будут позже***
###

## Запуск
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
Сервер будет доступен по `0.0.0.0:8080`

## Framework
Название | Ссылка
--- | ---
Vapor | https://github.com/vapor/vapor/
Vapor APNs | https://github.com/vapor/apns.git
Fluent | https://github.com/vapor/fluent
Fluent PostgreSQL | https://github.com/vapor/fluent-postgres-driver
