
<div align="center">
<h1 style="text-align: center;">🎮 Gamify.nvim 🎮</h1>

![logo](https://github.com/user-attachments/assets/d24d6a76-76cb-4a75-a862-0aa1764e5e13)

**Turn your Neovim into an RPG experience.**  
Track your activity, earn XP, level up, and unlock achievements while you code.

[Features](#features) • [Installation](#installation--usage) • [Mini-Games](#mini-games) • [Challenges](#gamify-katas) • [Achievements](#achievements)
</div>

---

## 🚀 Features

- **Unified Dashboard**: Access everything from one place with `:Gamify`.
- **Character Classes**: Are you a **Frontend Wizard**, **Systems Ninja**, or **Plugin Sorcerer**? Your role evolves based on your most-used languages!
- **XP & Leveling System**: Earn XP for writing code, fixing bugs, and completing challenges. Watch your progress bar grow!
- **Daily Quests**: 3 fresh objectives every day with progress tracking and a completion bonus.
- **Focus Combo**: Code uninterrupted to build a focus streak that multiplies your XP (up to x3).
- **Prestige System**: Hit the level cap, then prestige for a permanent XP bonus.
- **Activity Heatmap**: A GitHub-style contribution graph of your coding, right inside Neovim (`:GamifyHeatmap`).
- **Share Card**: Generate a shareable ASCII character card and yank it to your clipboard (`:GamifyShare`).
- **Mini-Games**: Take a break with built-in games like **Vim Snake**, **Saper (Minesweeper)**, and **Sudoku**.
- **Gamify Katas**: Solve 8 algorithmic challenges (Codewars-style) directly in your editor, with a bonus **kata of the day**.
- **Clean Code Bonus**: Get rewarded for saving files with zero errors (once per buffer, no grinding).
- **Achievement System**: 21 unique milestones with confetti effects and popups.
- **Statusline Component**: Show your level, XP bar, and streak in lualine/heirline.
- **Fully Configurable**: Tune every XP reward, quest, and feature via `setup()`.
- **Fresh Repo Support**: Works seamlessly even in brand-new git repositories.

---

## 📸 Screenshots

### The Dashboard
Level, XP bar, role, prestige, focus combo, progress to your next achievement, daily quests, and the menu — all from `:Gamify`.

<!-- TODO: screenshot of :Gamify dashboard -->
<!-- ![Dashboard](docs/screenshots/dashboard.png) -->

### Daily Quests
Three randomized objectives per day with live progress and a completion bonus.

<!-- TODO: screenshot of the Daily Quests section on the dashboard -->
<!-- ![Daily Quests](docs/screenshots/quests.png) -->

### Activity Heatmap
A GitHub-style contribution graph of your coding, via `:GamifyHeatmap`.

<!-- TODO: screenshot of :GamifyHeatmap -->
<!-- ![Heatmap](docs/screenshots/heatmap.png) -->

### Share Card
A shareable ASCII character card you can yank to your clipboard, via `:GamifyShare`.

<!-- TODO: screenshot of :GamifyShare card -->
<!-- ![Share Card](docs/screenshots/share-card.png) -->

### Vim Snake
<!-- TODO: screenshot of :GamifySnake -->
<!-- ![Snake](docs/screenshots/snake.png) -->

### Gamify Katas
The kata picker (with the ⭐ kata of the day) and the in-editor Lua solution buffer.

<!-- TODO: screenshot of :GamifyChallenges -->
<!-- ![Katas](docs/screenshots/katas.png) -->

> Screenshots are placeholders. Drop PNGs/GIFs into `docs/screenshots/` and uncomment the image lines above.

---

## 📦 Installation & Usage

### 1. Install via your preferred plugin manager

**lazy.nvim**
```lua
{
  'grzegorzszczepanek/gamify.nvim',
  config = function()
    require('gamify').setup()
  end,
}
```

> **Note:** `gamify.nvim` no longer auto-initializes on `require`. You must call
> `require('gamify').setup()` (optionally with a config table) for commands and
> tracking to be registered.

### 2. Commands
- **`:Gamify`** – Open the **Unified Dashboard** (Center of Command).
- **`:GamifySnake`** – Launch the **Vim Snake** mini-game.
- **`:GamifySaper`** – Launch the **Saper (Minesweeper)** mini-game.
- **`:GamifySudoku`** – Launch the **Sudoku** mini-game.
- **`:GamifyChallenges`** – Start solving **Gamify Katas**.
- **`:GamifyHeatmap`** – View your activity heatmap.
- **`:GamifyShare`** – Generate a shareable character card.
- **`:GamifyStats`** – Quick stats line via `vim.notify`.
- **`:GamifyPrestige`** – Prestige (resets XP for a permanent bonus).
- **`:GamifyReset`** – Wipe all progress (asks for confirmation).
- **`:LangStats`** – Detailed breakdown of lines per language.
- **`:Achievements`** – View your trophy room.

---

## 🐍 Mini-Games

### Vim Snake
Feeling stuck? Type `:GamifySnake` and use `h`, `j`, `k`, `l` to control the snake. Each 🍎 you eat gives you **10 XP**!

### Saper (Minesweeper)
Classic Minesweeper directly in your editor. Type `:GamifySaper`.
- **Controls**: `h, j, k, l` to move, `<Enter>` to reveal, `f` to flag.
- **Reward**: Win the game to earn **200 XP**!

### Sudoku
Classic Sudoku with difficulty levels. Type `:GamifySudoku`.
- **Controls**: `h, j, k, l` to move, `1-9` to enter numbers, `d` to change difficulty, `0/x` to clear.
- **Reward**: Solve the puzzle to earn up to **500 XP**!

---

## 🏆 Gamify Katas
Improve your Lua and algorithmic skills without leaving Neovim.
1. Open the menu via `:Gamify` and press `c` (or run `:GamifyChallenges`).
2. Select a challenge (e.g., *Reverse String*, *FizzBuzz*, *Fibonacci*).
3. Write your solution and press `<Enter>` to run tests.
4. Pass all tests to claim your reward!

There are **8 katas**, each solvable once for XP. One is the **⭐ Kata of the Day**
and awards **+50% XP** the first time you solve it each day. Solutions run in a
sandbox, so `solution` won't leak into your global environment.

---

## 🎯 Daily Quests & Combos

- **Daily Quests** — Every day you get 3 randomized objectives (write N lines,
  make N commits, fix bugs, solve a kata, play a game…). Progress is tracked
  live on the dashboard, and clearing all three grants a bonus.
- **Focus Combo** — Keep coding without long breaks to build a focus streak.
  Your XP multiplier rises the longer you stay in flow (up to x3), and resets
  after you go idle.
- **Prestige** — Once you reach the level cap (default 50), run `:GamifyPrestige`
  to reset your XP in exchange for a permanent XP bonus that stacks each rank.

---

## 🏅 Achievements

| **Achievement**            | **Description**                                                              | **XP**  |
|----------------------------|------------------------------------------------------------------------------|--------:|
| **Weekly Streak**          | Open Neovim every day for 7 consecutive days                                 | 500     |
| **Night Owl**              | Code for at least 3 hours between 11PM and 4AM five times                     | 1000    |
| **Early Bird**             | Code for at least 3 hours between 6AM and 11AM five times                     | 1000    |
| **Polyglot**               | Write at least 1000 lines in at least 10 languages                           | 5000    |
| **Commit Deity**           | Make 500 total commits in your coding journey                                | 8000    |
| **Get a Life!**            | Spend at least 200 hours in nvim                                             | 9000    |

*(And many more... type `:Achievements` to see them all!)*

---

## 📊 Statusline

Show your level, an XP bar, and your streak in your statusline:

```lua
-- lualine example
require('lualine').setup {
  sections = {
    lualine_x = {
      function() return require('gamify.logic').get_statusline_bar() end,
    },
  },
}
```

`get_statusline_bar(bar_width)` renders e.g. `Lvl 12 [████░░] 🔥7`.
For a minimal variant use `get_statusline_text()` → `Lvl 12 🔥 7`.

---

## 🛠️ Configuration

Pass a table to `setup()` to override any default. Shown below with defaults:

```lua
require('gamify').setup {
  xp = {
    per_lines = 10,        -- 1 XP per N lines written
    per_keypresses = 50,   -- 1 XP per N keypresses
    per_error_fixed = 5,   -- XP per resolved diagnostic error
    clean_code = 15,       -- XP for saving a buffer with zero errors
    new_day = 10,          -- XP for the first launch on a new day
    random_luck = 50,      -- XP for the rare lucky bonus
    snake_per_apple = 10,
    saper_win = 200,
  },
  clean_code_once_per_buffer = true, -- prevent `:w` XP farming
  random_luck_chance = 40,           -- 1-in-N chance per save / new day
  focus = {
    enabled = true,
    idle_timeout_sec = 120,  -- a longer gap resets the combo
    tier_seconds = 300,      -- every N focused seconds bumps the multiplier
    max_multiplier = 3.0,
  },
  quests = {
    enabled = true,
    count = 3,               -- quests generated per day
    completion_bonus = 200,  -- bonus XP for clearing all daily quests
  },
  leveling = { A = 0.001, B = 1.02 }, -- level = floor(1 + A * (xp ^ B))
  prestige = {
    enabled = true,
    level_required = 50,
    xp_bonus_per_rank = 0.05, -- +5% XP per prestige rank
  },
  ui = {
    confetti = true,
    popups = true,
    xp_popups = true,
    popup_timeout_ms = 5000,
  },
}
```

---

## 📜 License
Licensed under the [Apache License 2.0](LICENSE).
