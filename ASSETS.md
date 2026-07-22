# ASSETS.md — техзадание на визуальные ассеты MacClipbrd 0.0.1

Документ самодостаточен: его можно целиком отдать нейросети-генератору картинок
или дизайнеру. Все промпты — на английском, готовы к копированию как есть.

---

## 0. Контекст продукта (нужен генератору для попадания в стиль)

MacClipbrd — menu bar приложение для macOS 13+, менеджер истории буфера обмена
(аналог Win+V в Windows). Пишется на Swift/SwiftUI, распространяется как `.dmg`.

Что видит пользователь:

- В строке меню — маленькая монохромная иконка. Клик по ней или хоткей **⌥⌘V**
  открывает панель.
- Панель: окно **340×440 pt**, скруглённые углы (radius 10), фон
  `windowBackgroundColor`. Сверху поле поиска с `magnifyingglass`, ниже —
  разделитель, список записей, ещё разделитель, футер (счётчик записей,
  сегментированный переключатель EN/RU, кнопка Clear).
- Строка списка: текст в 3 строки, либо превью изображения 32×32 с подписью
  «Image» и размерами «1920×1080», либо системная иконка файла с именем и
  размером. Выделенная строка залита `Color.accentColor` (системный синий),
  текст на ней белый. При наведении справа появляется иконка `trash`.
- Пустое состояние: крупный `doc.on.clipboard` третичным цветом + текст.

Текущее состояние ассетов (проверено):

- **Кастомной иконки приложения нет.** В `Info.plist` отсутствует ключ
  `CFBundleIconFile`, `build-app.sh` создаёт `Contents/Resources`, но ничего
  туда не кладёт. В Dock/Finder показывается дефолтная «заготовка» macOS.
- **Иконка в menu bar** — SF Symbol `doc.on.clipboard`
  (`AppDelegate.swift:47`, `NSImage(systemSymbolName:)`). Это рабочий вариант,
  но неотличимый от десятка других утилит.

---

## 1. Единый визуальный язык

Одна и та же ДНК во всех генерируемых ассетах, чтобы иконка, баннер и фон DMG
читались как один продукт.

**Метафора:** стопка/каскад из трёх слоёв — «история», а не один буфер.
Верхний слой — активная запись, под ним со смещением ещё два. Метафора одна и
та же для иконки приложения, menu bar иконки и баннера.

**Палитра** (macOS-native, спокойная, без неона):

| Роль | HEX | Где |
|---|---|---|
| Акцент / системный синий | `#007AFF` | верхний слой, подсветка |
| Глубокий синий (тень слоёв) | `#0A4DA6` | нижние слои |
| Тёмный фон | `#1C1C1E` | подложка баннера, тёмная тема |
| Светлая поверхность | `#F5F5F7` | «бумага» слоёв, фон светлого баннера |
| Серый текст | `#8E8E93` | вторичные подписи |
| Белый | `#FFFFFF` | контур/блики |

**Стиль:** плоские геометрические формы с мягкими градиентами и одной
деликатной тенью — язык современных macOS-иконок (Things, Craft, Raycast).
Никакого скевоморфизма, никаких фотореалистичных текстур, никакого 3D-рендера
с бликами «как у Blender-туториала».

**Запрещено во всех промптах:** текст и буквы внутри изображения (кроме баннера,
где текст добавляется вручную), watermark, drop-shadow за пределами канвы,
фотореализм, стоковые «AI-градиенты» фуксия/циан, шум и гранж, скруглённая
рамка внутри самой картинки для иконки (систему squircle рисует сама Apple
только для App Store — для `.icns` маску рисуем мы, см. §2).

---

## 2. Иконка приложения (`.icns`)

### 2.1 Требования Apple

- Итоговый файл: `AppIcon.icns` в `MacClipbrd.app/Contents/Resources/`.
- Внутри `.icns` — 10 представлений: 16, 32, 128, 256, 512 pt, каждый в @1x и
  @2x. То есть пиксельные размеры: 16, 32, 32, 64, 128, 256, 256, 512, 512,
  1024.
- Формат исходника: **PNG, 1024×1024, sRGB, 32-бит с альфа-каналом**. Всё
  остальное генерируется из него скриптом (§2.4).
- **Форма — squircle** (Apple continuous rounded rectangle), а не круг и не
  квадрат. На канве 1024×1024 корпус иконки занимает **824×824 px по центру**
  (по 100 px прозрачных полей с каждой стороны — это safe area, туда macOS
  «дышит» тенью и туда попадает бейдж уведомлений). Радиус скругления корпуса —
  **~185 px** (0.2246 от стороны корпуса).
- Значимая графика внутри корпуса — не ближе **80 px** к краю корпуса, иначе
  на 16×16 всё слипнется.
- Тень встроена в PNG (мягкая, вниз, ~2% чёрного), но не выходит за 1024.
- Фон корпуса — непрозрачный; прозрачны только поля вокруг squircle.

Чего избегать: круглой иконки; иконки-«наклейки» без корпуса; тонких линий
меньше 8 px на 1024 (исчезнут на 32×32); мелких деталей и надписей; полного
копирования системных символов macOS; фирменного логотипа Apple/яблока.

> Замечание про macOS 26 (Tahoe) и Icon Composer: Apple ввела многослойные
> `.icon`-файлы со стеклянными эффектами. Для 0.0.1 это избыточно —
> классический `.icns` из одного PNG корректно работает на всех версиях от
> 13 до 26. Многослойность оставить на потом.

### 2.2 Промпт для нейросети — светлый вариант (основной)

```
A macOS application icon, flat vector style, centered on a transparent
1024x1024 canvas. The icon body is a squircle (Apple-style continuous rounded
square) occupying the central 824x824 pixels with 100px of transparent padding
on all sides, corner radius about 185px. The squircle has a smooth top-to-bottom
gradient from #0A84FF to #0055D4, plus a very subtle 1px lighter inner rim at
the top edge.

Inside the squircle: three stacked rounded rectangles representing a stack of
clipboard history cards, arranged as a cascade going up-and-left, each slightly
offset by about 40px. The bottom two cards are semi-transparent white (30% and
60% opacity), the top front card is solid off-white #F5F5F7 with a soft shadow
beneath it. The top card shows three short horizontal grey lines (#8E8E93)
suggesting lines of copied text, and a small blue rounded square in its upper
left corner. Above the top card sits a small clipboard clip shape in white,
centered on its top edge.

Style: modern flat vector, clean geometry, soft realistic drop shadow inside the
squircle only, no outer shadow beyond the canvas, no text, no letters, no
watermark, no photorealism, no 3D render, no gloss highlights, no noise or
grain. Crisp edges, readable when scaled down to 32x32 pixels.
```

### 2.3 Промпт — тёмный вариант (запасной, если светлый «плывёт»)

```
A macOS application icon, flat vector style, transparent 1024x1024 canvas.
Central squircle 824x824px, corner radius 185px, 100px transparent padding.
The squircle body is deep graphite #1C1C1E with a barely visible vertical
gradient to #2C2C2E. Inside: three cascading rounded cards offset up-and-left,
the back two rendered as thin 10px outlines in #007AFF at 40% and 70% opacity,
the front card filled solid #007AFF with three short white horizontal lines on
it. Minimal, high contrast, geometric.

No text, no letters, no watermark, no photorealism, no 3D, no gloss, no grain.
Must stay legible at 32x32 pixels.
```

### 2.4 Что делать руками — сборка `.icns`

Нейросеть отдаёт **только** `icon_1024.png`. Всё остальное — скриптом, потому
что генератору нельзя доверять пиксельную точность масштабов и потому что
`.icns` — контейнер, а не картинка.

```bash
# 0. Проверить, что исходник ровно 1024x1024 и с альфой
sips -g pixelWidth -g pixelHeight -g hasAlpha icon_1024.png

# 1. Разложить в iconset
mkdir -p AppIcon.iconset
sips -z 16   16   icon_1024.png --out AppIcon.iconset/icon_16x16.png
sips -z 32   32   icon_1024.png --out AppIcon.iconset/icon_16x16@2x.png
sips -z 32   32   icon_1024.png --out AppIcon.iconset/icon_32x32.png
sips -z 64   64   icon_1024.png --out AppIcon.iconset/icon_32x32@2x.png
sips -z 128  128  icon_1024.png --out AppIcon.iconset/icon_128x128.png
sips -z 256  256  icon_1024.png --out AppIcon.iconset/icon_128x128@2x.png
sips -z 256  256  icon_1024.png --out AppIcon.iconset/icon_256x256.png
sips -z 512  512  icon_1024.png --out AppIcon.iconset/icon_256x256@2x.png
sips -z 512  512  icon_1024.png --out AppIcon.iconset/icon_512x512.png
cp                icon_1024.png     AppIcon.iconset/icon_512x512@2x.png

# 2. Собрать контейнер
iconutil -c icns AppIcon.iconset -o AppIcon.icns

# 3. Убрать промежуточную папку
rm -rf AppIcon.iconset
```

Готовый `AppIcon.icns` положить в корень репозитория (рядом с `Info.plist`) и
закоммитить — исходник `icon_1024.png` тоже стоит хранить, в `Assets/`.

**Подключение в `Info.plist`** — добавить в `<dict>`:

```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
```

(без расширения `.icns` — так требует загрузчик бандлов).

**Подключение в `build-app.sh`** — после строки `cp Info.plist
"$APP/Contents/Info.plist"` добавить:

```bash
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
```

Копировать ресурс нужно **до** `codesign`, иначе подпись окажется невалидной.
В текущем скрипте подпись идёт ниже — место подходит.

После первой сборки Finder может показывать старую иконку из кэша:
`killall Dock` или `touch MacClipbrd.app`.

---

## 3. Иконка в menu bar (template image)

### 3.1 Требования

- Это **template image**: рисунок только чёрным (`#000000`) на прозрачном фоне.
  Цвет не используется вообще — оттенки передаются альфа-каналом. macOS сама
  инвертирует его в белый в тёмной теме и подсвечивает при активном состоянии.
- Имя файла обязано заканчиваться на `Template`, тогда AppKit выставляет
  `isTemplate = true` автоматически: `MenuBarIconTemplate.pdf` либо
  `MenuBarIconTemplate.png` + `MenuBarIconTemplate@2x.png`.
- Размер: рабочая область **16×16 pt** (PNG: 16×16 и 32×32 px). Реальный рисунок
  внутри — примерно 15×15 pt для строки меню высотой 22 pt; сверху/снизу по
  1 pt воздуха.
- **Предпочтительный формат — PDF** (векторный, один файл, масштабируется под
  любую плотность экрана и под будущие изменения высоты статус-бара).
  PNG @1x/@2x — запасной вариант, если вектора нет.
- Толщина штриха — **1.5 pt** при 16 pt канве. Тоньше 1 pt — пропадёт, толще
  2 pt — будет выглядеть жирнее системных иконок рядом.
- Без заливок «в цвет», без градиентов, без полутонов серым (только альфа),
  без текста, без обводки-рамки вокруг иконки.

### 3.2 Промпт

```
A monochrome macOS menu bar template icon on a fully transparent background,
square 512x512 canvas for later downscaling to 16x16 points. Pure black
(#000000) strokes only, no colour, no grey fill, no gradient.

The shape: three overlapping rounded-rectangle card outlines arranged as a small
cascade going up-and-left, drawn in a uniform stroke weight equal to 1.5 points
at 16pt scale (i.e. 48px stroke on a 512px canvas), rounded line joins and caps.
The front card has a small clipboard clip notch on its top edge. Geometry only,
strictly aligned to a pixel grid, symmetric, generous internal spacing.

Flat line-art in the visual language of Apple SF Symbols: minimal, even weight,
no perspective, no shading, no text, no watermark, no background shape, no
border frame. Must stay legible at 16x16 pixels.
```

### 3.3 Что делать руками

Нейросеть даёт растр — его нужно **обвести вектором** (Figma, Sketch, Inkscape,
Vectornator) и экспортировать в PDF 16×16 pt. Прямая генерация PDF нейросетью
невозможна, а растр из генератора почти наверняка будет с полутонами и
неровными краями — на 16 px это видно.

Экспорт PNG-варианта, если вектор не делается:

```bash
sips -z 16 16 menubar_raw.png --out MenuBarIconTemplate.png
sips -z 32 32 menubar_raw.png --out MenuBarIconTemplate@2x.png
```

Подключение в коде (`AppDelegate.swift:47`, вместо SF Symbol):

```swift
button.image = NSImage(named: "MenuBarIconTemplate")
button.image?.isTemplate = true
button.image?.accessibilityDescription = "MacClipbrd"
```

Файл кладётся в `Contents/Resources/` тем же способом, что и `.icns`
(строка `cp` в `build-app.sh`).

**Решение для 0.0.1:** этот ассет — необязательный. SF Symbol
`doc.on.clipboard` уже даёт корректное template-поведение, автоинверсию и
идеальную резкость. Кастомная иконка строки меню имеет смысл только если
готова векторная версия; иначе релиз выпускается на SF Symbol.

---

## 4. Баннер репозитория и social preview

Один файл решает обе задачи, если сделать его 1280×640: GitHub принимает
social preview до 1 MB и рекомендует именно 1280×640 (соотношение 2:1),
а тот же файл можно вставить первой строкой в README.

- **Размер:** 1280×640 px, PNG, sRGB, до 1 MB.
- **Safe area:** GitHub обрезает превью по краям в разных клиентах — весь
  смысловой контент держать внутри центральных **1120×520 px** (по 80 px полей
  сверху/снизу и по 80 px слева/справа).
- Логотип и текст **накладываются вручную** поверх сгенерированного фона —
  нейросети не рисуют читаемую типографику, и название продукта не должно
  зависеть от галлюцинаций генератора.
- Куда положить: `Assets/banner.png`, в README первой строкой
  `![MacClipbrd](Assets/banner.png)`, и загрузить в Settings → General →
  Social preview.

### 4.1 Промпт (фон + сцена, без текста)

```
A wide 1280x640 hero banner background for a macOS developer tool, flat vector
illustration, dark theme. Background: deep graphite #1C1C1E with a very soft
radial glow of #007AFF at 12% opacity behind the centre-right, and a faint
large-scale dot grid at 4% white opacity.

On the right half: a stylised macOS floating panel, a tall rounded rectangle
with a 12px corner radius, portrait proportions roughly 340 by 440, filled with
#2C2C2E and a 1px #3A3A3C border. Inside it, from top to bottom: a search field
bar, a thin divider, then six list rows — the second row highlighted with a
solid #007AFF fill, the others showing short grey placeholder bars of varying
length, one row showing a small square image thumbnail, one row showing a small
document icon. All content rendered as abstract grey bars, no readable letters.

Behind and to the left of the panel: two more identical panels fanned out and
receding, at 40% and 20% opacity, suggesting a stack of clipboard history.
The left third of the banner is deliberately empty dark space reserved for a
logo and title to be added later.

Style: crisp flat vector UI illustration, subtle depth, generous negative space,
Apple software marketing aesthetic. No text, no letters, no numbers, no
watermark, no photorealism, no 3D render, no people, no hands, no laptop mockup.
```

### 4.2 Что делать руками

Поверх сгенерированного фона в Figma/Preview добавить в левую треть:
`AppIcon` 128×128, ниже заголовок **MacClipbrd** (SF Pro Display Bold, 64 pt,
`#FFFFFF`), под ним подзаголовок «Clipboard history for macOS. The ⌥⌘V you were
missing.» (SF Pro Text Regular, 24 pt, `#8E8E93`).

---

## 5. Скриншоты для README

**Это делает разработчик сам, вручную, на реальном приложении. Нейросети —
запрещено.** Причины: сгенерированный «скриншот» — это обман пользователя,
в нём будет нечитаемый текст, а любое расхождение с реальным UI сразу заметно
и подрывает доверие к релизу. Реальный скриншот снимается за минуту.

Как снимать:

- ⇧⌘4, затем **пробел** → курсор становится камерой → клик по панели: macOS
  снимет окно с прозрачным фоном и родной тенью, ровно по границам.
- Экран Retina — итог получится @2x, это правильно. В README вставлять с
  ограничением ширины: `<img src="Assets/shot-main.png" width="380">`.
- Тема macOS: снимать в **светлой** — на GitHub README чаще читают в светлой.
- Обои рабочего стола на время съёмки поменять на нейтральные (Settings →
  Wallpaper → однотонный тёмно-серый), чтобы тень панели легла ровно.
- Убрать из истории всё личное перед съёмкой (кнопка Clear в футере), потом
  набить демо-данными.

Какие сцены и с какими данными:

| Файл | Сцена | Что должно быть в истории |
|---|---|---|
| `shot-main.png` | Панель открыта, поиск пустой, выделена вторая строка | Сверху вниз: текст `https://github.com/…/multibuf-mac`; изображение-скриншот с подписью `Image · 2560×1440`; файл `Invoice-2026-07.pdf · 248 KB`; длинный текст на 3 строки (абзац из README); текст `ssh user@server.example.com`; мультифайл `report.xlsx, chart.png · 2 items · 1,4 MB`. Футер показывает `6 items`, переключатель на EN |
| `shot-search.png` | В поле поиска набрано `pdf`, список отфильтрован до 1–2 записей | Те же данные, что и выше; видно, что фильтр ловит и текст, и имена файлов |
| `shot-menubar.png` | Кроп правой части строки меню, панель раскрыта под иконкой | Только строка меню + верх панели, ширина кропа ~600 px. Показывает второй способ открытия |
| `shot-ru.png` | Та же панель с переключателем на RU | Опционально, для секции про локализацию |

Демо-данные не должны содержать реальных путей вида `/Users/ivanzhuravlev/…` —
для файловых записей заранее скопировать файлы из `~/Desktop/Demo/`.

---

## 6. Опционально: оформление DMG

Нужно только если релиз собирается через `create-dmg` или Disk Utility с
кастомным фоном. Для 0.0.1 полностью необязательно — простой DMG без фона
выглядит нормально.

- **Фон DMG:** `dmg-background.png`, 660×400 px @1x + `dmg-background@2x.png`,
  1320×800 px. Формат PNG. Слева на фоне — место под иконку `MacClipbrd.app`
  (позиция ~x160, y185), справа — под алиас `/Applications` (~x500, y185),
  между ними стрелка.
- **Иконка тома DMG:** отдельный `.icns` не нужен — используется тот же
  `AppIcon.icns`.

### 6.1 Промпт для фона DMG

```
A macOS DMG installer window background, 1320x800 pixels, extremely minimal.
Background is a smooth vertical gradient from #F5F5F7 at the top to #EAEAEC at
the bottom (light theme), completely clean, no texture, no noise.

In the centre, a single thin arrow pointing from left to right, drawn as a
2px stroke in #C7C7CC with a simple triangular head, spanning roughly from
x=440 to x=880 at the vertical centre. Nothing else on the canvas — the left
and right thirds must stay completely empty, they will be occupied by file
icons placed by the installer.

No text, no letters, no logos, no watermark, no borders, no shadows, no
photorealism, no 3D. Flat, calm, Apple installer aesthetic.
```

---

## 7. Сводка: нейросеть vs. руки

| Ассет | Кто делает | Комментарий |
|---|---|---|
| `icon_1024.png` | **нейросеть** | Один PNG, дальше скрипт |
| `AppIcon.icns` (10 размеров) | **скрипт** | `sips` + `iconutil`, §2.4 |
| `CFBundleIconFile` + `cp` в build-app.sh | **руки** | 2 строки, §2.4 |
| Menu bar template icon — эскиз | **нейросеть** | §3.2 |
| Menu bar template icon — вектор/PDF | **руки** | Обводка в Figma/Inkscape, иначе не брать вовсе |
| Фон баннера 1280×640 | **нейросеть** | §4.1 |
| Логотип и текст на баннере | **руки** | Типографику генератору не отдавать |
| Скриншоты README | **только руки** | ⇧⌘4 + пробел, §5 |
| Фон DMG | **нейросеть** | Опционально, §6.1 |

Порядок работ: иконка приложения → сборка `.icns` и подключение → скриншоты
(они уже с новой иконкой в строке меню) → баннер → DMG.

---

## 8. Чем генерировать

**Основной выбор: Google AI Studio (aistudio.google.com), модель Gemini
image generation («Nano Banana»).**

Почему именно он для этой задачи:

- Бесплатный веб-интерфейс с лимитом порядка сотен генераций в сутки — заведомо
  больше, чем нужно на 4 ассета с итерациями. (На API-доступ бесплатный тариф
  по картинкам сейчас не распространяется — работать нужно именно через веб-UI
  AI Studio или приложение Gemini.)
- Выход 1024×1024 без watermark — это ровно тот исходник, который требует §2.4.
- Главное преимущество под эту задачу: **итеративное редактирование в диалоге**.
  Иконка почти никогда не выходит с первого раза, и возможность сказать
  «сдвинь карточки левее, убери блик, увеличь поля до 100 px» без перегенерации
  всей картинки экономит больше времени, чем качество любой отдельной модели.
- Хорошо держит длинные структурные промпты с конкретными пикселями и HEX —
  как раз формат промптов выше.

Ограничение, которое надо знать: на бесплатном тарифе Google оставляет за собой
право использовать ваши данные для обучения, а коммерческие права на выход
ограничены. Для MIT-проекта это приемлемо, для платного продукта — читать
условия.

**Запасной вариант: FLUX.1 Krea [dev] на Hugging Face Spaces**
(`huggingface.co/spaces/black-forest-labs/FLUX.1-Krea-dev`) — бесплатно, без
регистрации, открытая модель, при желании ставится локально. Диалогового
редактирования нет (только перегенерация с новым seed), зато чище работает с
плоской векторной геометрией и меньше «замыливает» края — если Gemini упорно
подмешивает в иконку 3D-блики, идти сюда.

Что делать после генерации в обоих случаях:

```bash
# Убедиться, что альфа-канал есть, а размер ровно 1024
sips -g pixelWidth -g pixelHeight -g hasAlpha icon_raw.png
```

Если `hasAlpha: no` — фон залит белым, его нужно вырезать вручную (Preview →
Instant Alpha, или `rembg`), либо перегенерировать с явным упором на
`transparent background` в промпте.

---

## Источники

- [Gemini Image Generation Free Tier: App, AI Studio, or API?](https://www.aifreeapi.com/en/posts/gemini-image-generation-free-tier)
- [Gemini Image Generation API Free Tier (2026)](https://www.aifreeapi.com/en/posts/gemini-image-generation-free-api)
- [FLUX.1 Krea Dev — Hugging Face Space](https://huggingface.co/spaces/black-forest-labs/FLUX.1-Krea-dev)
- [black-forest-labs/FLUX.1-Krea-dev — модель и лицензия](https://huggingface.co/black-forest-labs/FLUX.1-Krea-dev)
