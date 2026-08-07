# Shindo Toolkit

[English version](README.md)

[![CI](https://github.com/l3wisky/shindo-toolkit/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/l3wisky/shindo-toolkit/actions/workflows/ci.yml)
[![Actions Security](https://github.com/l3wisky/shindo-toolkit/actions/workflows/actions-security.yml/badge.svg?branch=main)](https://github.com/l3wisky/shindo-toolkit/actions/workflows/actions-security.yml)
[![Release](https://img.shields.io/github/v/release/l3wisky/shindo-toolkit)](https://github.com/l3wisky/shindo-toolkit/releases/latest)

Shindo Toolkit — небольшой двуязычный Luau-инструмент для стабильных QOL- и FUN-сценариев. Проект намеренно не
добавляет автоматизацию боя, фарма или PVP. Это неофициальный проект, не связанный с RELL World, Roblox
Corporation или Sirius Software.

Версия 1.0.0 превращает исходный набор удалённо загружаемых модулей в воспроизводимый релиз: один bundle проекта,
фиксированный toolchain, явные границы отказа, безопасная диагностика и укреплённая цепочка GitHub Actions.

## Стабильный лоадер

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/l3wisky/shindo-toolkit/main/loader.luau"))()
```

Стабильный лоадер загружает единый файл из последнего опубликованного GitHub Release. Релиз также содержит
`SHA256SUMS` и provenance-attestation от GitHub. Код из ветки `dev` стабильным лоадером не исполняется.

## Dev-лоадер

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/l3wisky/shindo-toolkit/dev/loader.dev.luau"))()
```

Dev-лоадер получает отдельные модули из меняющейся ветки `dev`. Он использует отдельные локальные настройки и
предназначен только для проверки ещё не выпущенных изменений.

## Возможности

- Применение и восстановление Bloodline и Kenjutsu с сохранением исходного значения на время серверной сессии.
- Переопределение RCGenkai с такой же безопасной семантикой восстановления.
- Загрузка наряда, телепорт домой, переподключение и подтверждаемый откат/возврат даты.
- Просмотр данных игрока с необязательной поддержкой буфера обмена.
- Английский и русский интерфейс, шесть тем Rayfield, уведомления и локальные настройки.
- Диагностика возможностей executor-а и доступности игровых целей. Отчёт не содержит имя или ID пользователя,
  Job ID, код приватного сервера и значения сохранённых настроек.
- Безопасная перезагрузка: ошибка зависимости или построения нового UI не уничтожает предыдущую рабочую сессию.

Игровая структура может измениться без участия проекта. Отсутствующая цель отключает только конкретное действие
и показывает понятную ошибку; весь интерфейс продолжает работать.

## Требования и границы доверия

Лоадеру необходимы `game:HttpGet` и `loadstring`. Файловая система и буфер обмена необязательны: без них toolkit
продолжит работать, но настройки могут не сохраняться, а кнопки копирования сообщат об отсутствии возможности.

Во время работы проект загружает только:

1. релизный bundle Shindo Toolkit (либо raw-модули `dev`, если явно выбран dev-лоадер);
2. версионированный релизный файл Rayfield Gen2 1.1.0, указанный в [NOTICE](NOTICE).

Телеметрии и аналитики нет. Перед публикацией релиза сборка сверяет Rayfield с записанным SHA-256. Поведение
executor-ов различается; при проблемах совместимости используйте Диагностику и никогда не прикладывайте к отчёту
код приватного сервера или секреты аккаунта.

## Разработка

[Rokit](https://github.com/rojo-rbx/rokit) устанавливает точные версии инструментов из `rokit.toml`:

```bash
rokit install
scripts/ci.sh
```

Та же команда в CI проверяет форматирование, Selene и официальный анализатор Luau, запускает
unit/invariant-тесты, компилирует все Luau-файлы, собирает bundle, сверяет метаданные релиза и checksum Rayfield,
а также ищет whitespace-ошибки Git. Для сборки используйте только `scripts/build.sh`; файлы в `dist/` не
коммитятся.

Жизненный цикл релиза намеренно короткий:

1. изменения попадают в `dev` через проверенный зелёный pull request;
2. promotion PR переносит протестированный commit из `dev` в `main`;
3. release workflow заново собирает `main`, создаёт draft, подписывает и загружает файлы, затем публикует релиз.

Перед изменением runtime или выпуска прочитайте [CONTRIBUTING.md](CONTRIBUTING.md),
[описание архитектуры](docs/ARCHITECTURE.md) и [release checklist](docs/RELEASE_CHECKLIST.md).

## Поддержка и безопасность

Для обычной ошибки используйте структурированный bug report и приложите вывод Диагностики. Уязвимость лоадера,
workflow или релизной цепочки отправляйте по инструкции из [SECURITY.md](SECURITY.md), а не в публичный issue.

## Лицензия

Исходный код доступен по [PolyForm Noncommercial License 1.0.0](LICENSE). Уведомления о сторонних компонентах — в
[NOTICE](NOTICE).
