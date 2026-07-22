# Публикация MacClipbrd в Homebrew

Короткий вывод: **в официальный `homebrew-cask` сейчас нельзя** (не проходит порог
заметности), поэтому публикуемся через **собственный tap**. Но и это имеет смысл
делать только после того, как появятся нормальные GitHub Releases с готовым `.dmg`.
Порядок: сначала Releases → потом tap.

---

## 1. Официальный homebrew-cask — почему пока нет

Homebrew отклоняет casks из репозиториев, которые «недостаточно заметны». Актуальные
пороги:

| Кто подаёт | forks | watchers | stars |
|------------|-------|----------|-------|
| Сторонний PR | 30 | 30 | 75 |
| Сам автор (self-submit) | 90 | 90 | 225 |

У `Zzzhura/MacClipbrd` сейчас 0 — PR закроют автоматически. Обходить это нет смысла.

Что при этом Homebrew **не** требует:
- Developer ID / нотаризация **не обязательны**. Формального запрета на неподписанные
  приложения в правилах нет. Ограничение одно: cask **не должен требовать отключения
  Gatekeeper или SIP**. Наш кейс (right-click → Open или «Open Anyway») это правило не
  нарушает, но ухудшает UX — см. ниже про `--no-quarantine`.
- Никакого требования к конкретной схеме версий, кроме «отслеживать стабильный канал,
  рекомендованный большинству пользователей».

Вернуться к официальному репозиторию стоит, когда наберётся ~75+ звёзд и будет
регулярный релизный цикл.

---

## 2. Собственный tap (рабочий вариант на сейчас)

### 2.1. Создать репозиторий
Имя **обязано** начинаться с `homebrew-`:

```
github.com/Zzzhura/homebrew-macclipbrd
```

Структура:
```
homebrew-macclipbrd/
├── Casks/
│   └── macclipbrd.rb
└── README.md
```

### 2.2. Готовый Casks/macclipbrd.rb (версия 0.0.1)

Рассчитан на релиз-ассет `MacClipbrd-0.0.1.dmg`, приложенный к тегу `v0.0.1`.
`sha256` подставить командой из п. 4.

```ruby
cask "macclipbrd" do
  version "0.0.1"
  sha256 "REPLACE_WITH_REAL_SHA256"

  url "https://github.com/Zzzhura/MacClipbrd/releases/download/v#{version}/MacClipbrd-#{version}.dmg",
      verified: "github.com/Zzzhura/MacClipbrd/"
  name "MacClipbrd"
  desc "Clipboard history manager for macOS (Win+V equivalent)"
  homepage "https://github.com/Zzzhura/MacClipbrd"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "MacClipbrd.app"

  zap trash: [
    "~/Library/Application Support/MacClipbrd",
    "~/Library/Preferences/com.macclipbrd.app.plist",
    "~/Library/Saved Application State/com.macclipbrd.app.savedState",
  ]
end
```

Примечания:
- `verified:` нужен, потому что домен `url` (github.com) отличается от `homepage` —
  без него `brew audit` ругается.
- `auto_updates` **не ставим**: у приложения нет встроенного автообновления
  (Sparkle и т.п.). Ставить `true` — только если появится авто-апдейтер.
- `depends_on macos: ">= :ventura"` = macOS 13+, совпадает с `Package.swift`.
- TCC-грант Accessibility через `zap` убрать нельзя (это системная база), это нормально.

### 2.3. Как ставит пользователь
```bash
brew tap zzzhura/macclipbrd
brew install --cask macclipbrd
```
Одной строкой без явного tap:
```bash
brew install --cask zzzhura/macclipbrd/macclipbrd
```

### 2.4. Про quarantine и неподписанное приложение
Так как бандл подписан только самоподписанным «MacClipbrd Dev», после `brew install`
Gatekeeper всё равно будет ругаться при первом запуске. Варианты:
- **Оставить как есть** — в README tap-репо написать «при первом запуске: right-click →
  Open, либо System Settings → Privacy & Security → Open Anyway». На macOS 15 двойной
  клик из Gatekeeper уже не всегда даёт «Open Anyway» из диалога, надёжнее через
  Настройки.
- Добавить в cask `quarantine: false` — **не рекомендуется**: снимает проверку
  Gatekeeper, `brew audit` это не пропустит в официальный репозиторий, а для tap это
  ослабление безопасности пользователя. Оставь запуск через «Open Anyway».
- Правильное решение на будущее — Developer ID ($99/год) + нотаризация: тогда никаких
  предупреждений и путь в официальный homebrew-cask открыт.

---

## 3. `.dmg` vs `.zip` в релизе

Для cask поддерживаются оба, стенза `app "MacClipbrd.app"` одинаковая. Разница:
- **`.dmg`** — привычный для macOS формат, пользователь при желании ставит и вручную
  перетаскиванием. Рекомендую его как основной ассет релиза.
- **`.zip`** — проще собрать (`ditto -c -k --keepParent`), но для GUI-утилиты dmg
  выглядит «нативнее».

На `livecheck` формат не влияет: `strategy :github_latest` смотрит на теги/релизы репо,
а не на имя файла. Главное — держать стабильный шаблон имени ассета
(`MacClipbrd-<version>.dmg`), чтобы `url` собирался из `#{version}`.

Сборку dmg добавить в `build-app.sh` после подписи, например:
```bash
hdiutil create -volname "MacClipbrd" -srcfolder "$APP" -ov -format UDZO \
  "MacClipbrd-${VERSION}.dmg"
```

---

## 4. Автоматизация обновления cask

### Подсчёт sha256 вручную (для первого раза)
```bash
shasum -a 256 MacClipbrd-0.0.1.dmg
```

### Вариант A — самый простой: `brew bump-cask-pr`
Из машины с установленным Homebrew, после публикации нового тега/релиза:
```bash
brew bump-cask-pr --version 0.0.2 zzzhura/macclipbrd/macclipbrd
```
Сам скачает новый ассет, посчитает sha256, откроет PR (или коммит) в tap-репо.

### Вариант B — GitHub Actions в tap-репозитории
Workflow, который по `workflow_dispatch` или по вебхуку релиза из основного репо
обновляет cask. Минимальный шаг подсчёта sha и правки версии:

```yaml
# .github/workflows/bump.yml в homebrew-macclipbrd
name: Bump cask
on:
  workflow_dispatch:
    inputs:
      version: { required: true }
jobs:
  bump:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Compute sha256
        run: |
          V="${{ github.event.inputs.version }}"
          URL="https://github.com/Zzzhura/MacClipbrd/releases/download/v$V/MacClipbrd-$V.dmg"
          curl -sL "$URL" -o app.dmg
          SHA=$(shasum -a 256 app.dmg | awk '{print $1}')
          sed -i '' -E "s/version \".*\"/version \"$V\"/" Casks/macclipbrd.rb
          sed -i '' -E "s/sha256 \".*\"/sha256 \"$SHA\"/" Casks/macclipbrd.rb
      - name: Commit
        run: |
          git config user.name github-actions
          git config user.email actions@github.com
          git commit -am "macclipbrd ${{ github.event.inputs.version }}"
          git push
```

Для 0.0.x достаточно варианта A вручную — Actions заводить, когда релизы станут частыми.

---

## 5. Честная оценка: нужен ли Homebrew сейчас

**Сначала GitHub Releases, Homebrew — потом.** Обоснование:
- Cask физически нечем наполнить, пока нет релиз-ассета со стабильным URL и sha256.
- Пользы от tap на старте немного: установка через tap требует двух команд и всё равно
  упирается в Gatekeeper из-за отсутствия нотаризации — то есть трения не меньше, чем
  при скачивании dmg со страницы Releases.
- Официальный homebrew-cask закрыт по заметности.

Порядок действий:
1. Привести версии в `Info.plist` к `0.0.1` (сейчас `1.0`).
2. Добавить сборку `.dmg` в `build-app.sh`.
3. Настроить GitHub Actions на `macos-14` для сборки и прикладывания dmg к релизу по
   тегу `v*`.
4. Выпустить тег `v0.0.1` + release с `MacClipbrd-0.0.1.dmg`.
5. (Опционально, сразу после) создать tap `homebrew-macclipbrd` с cask из п. 2.2.
6. Набирать звёзды → при ~75+ подать в официальный homebrew-cask.
