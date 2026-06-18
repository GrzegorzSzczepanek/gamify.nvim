
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
- **Avatar Companion**: Design your own character (`:GamifyAvatar`) and pin it to a screen corner with cute idle animations.
- **Mini-Games**: Take a break with built-in games like **Vim Snake**, **Saper (Minesweeper)**, **Sudoku**, and **Gomoku** (5-in-a-row, with local & LAN play).
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
<img width="1700" height="1013" alt="image" src="https://github.com/user-attachments/assets/2ee9536d-0c8e-4eb1-88f1-8248df3b1132" />


### Screenshots
<img width="2028" height="1594" alt="image" src="https://github.com/user-attachments/assets/a1505784-f629-40cd-9bf4-1af510c990bb" />

### Activity Heatmap
A GitHub-style contribution graph of your coding, via `:GamifyHeatmap`.
<img width="524" height="379" alt="image" src="https://github.com/user-attachments/assets/c7a2c797-069f-48e6-9b49-8a28edc2ba5e" />


### Share Card
A shareable ASCII character card you can yank to your clipboard, via `:GamifyShare`.
<img width="436" height="322" alt="image" src="https://github.com/user-attachments/assets/1373860f-9e7f-4eda-b5f8-8537b8bdb1e1" />


### Gamify Katas
The kata picker (with the ⭐ kata of the day) and the in-editor Lua solution buffer.
<img width="480" height="318" alt="image" src="https://github.com/user-attachments/assets/77e44a98-186c-460f-8a74-683acdd2c955" />
<img width="716" height="422" alt="image" src="https://github.com/user-attachments/assets/5cb8ecec-2984-4cd9-9c75-339a900bca4a" />


### Gomoku (5-in-a-row)
The 20×20 board in action — local hot-seat or LAN multiplayer (`:Gomoku`).
<img width="1710" height="1112" alt="image" src="https://github.com/user-attachments/assets/a8c80b52-dcd6-4a3d-bb96-8db5358a7fde" />


### Avatar Companion
Build your own character with `:GamifyAvatar` and let it sit in the corner with cute idle animations (blink, bounce, wave).
<img width="450" height="400" alt="image" src="https://github.com/user-attachments/assets/295530ed-a626-4b3b-9723-9849767d38bf" />
<img width="264" height="358" alt="Screen Recording 2026-06-18 at 15 04 52" src="https://github.com/user-attachments/assets/22365663-19c2-4942-bc5d-ca380fc40b73" />


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
- **`:Gomoku`** – Play **Gomoku** (5-in-a-row on 20×20) locally; `:Gomoku host [port]` / `:Gomoku join <ip> [port]` for LAN.
- **`:GamifyChallenges`** – Start solving **Gamify Katas**.
- **`:GamifyHeatmap`** – View your activity heatmap.
- **`:GamifyAvatar`** – Open the **avatar generator**; `:GamifyAvatar show`/`hide`/`toggle` control the corner companion, `:GamifyAvatar anim on|off` toggles animations, `:GamifyAvatar corner <pos>` moves it.
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

### Gomoku (5-in-a-row)
Tic-tac-toe's big sibling: a **20×20** board where you win by lining up **five** stones
in a row — horizontally, vertically, or diagonally. Play side-by-side on one machine,
or against a friend over your local network.

<!-- TODO: screenshot of :Gomoku -->
<!-- ![Gomoku](docs/screenshots/gomoku.png) -->

#### Controls
| Key | Action |
|-----|--------|
| `h` `j` `k` `l` | Move the cursor around the board |
| `<Enter>` / `<Space>` | Place a stone on the current cell |
| `r` | Rematch / clear the board (local mode only) |
| `q` / `<Esc>` | Quit back to the dashboard |

`X` always moves first. Win a game to earn **150 XP**.

#### Local mode (one machine, two players)
Just run:
```vim
:Gomoku
```
Two players share the keyboard and take turns placing `X` and `O`. Open it from the
dashboard too: press `t` in `:Gamify`.

#### LAN mode (two machines on the same network)
Play over TCP — no servers, accounts, or extra dependencies. One player **hosts**, the
other **joins**.

1. **Host** (this player is `X` and moves first):
   ```vim
   :Gomoku host 5050
   ```
   Neovim starts listening on port `5050` and waits for an opponent.

2. Find the host's **LAN IP address** (e.g. `192.168.1.42`):
   - Linux/macOS: `ip addr` or `ifconfig` (look for a `192.168.x.x` / `10.x.x.x` address).
   - macOS: System Settings → Network, or `ipconfig getifaddr en0`.

3. **Join** from the second machine (this player is `O`):
   ```vim
   :Gomoku join 192.168.1.42 5050
   ```

Once connected, both boards open and moves sync automatically — you can only place a
stone on your turn. The port is `5050` by default but you can pass any free port, as
long as host and join use the same one.

> **Note:** A rematch (`r`) currently only works in local mode. Over LAN, restart the
> game to play again. You may also need to allow the chosen port through both machines'
> firewalls.

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
  avatar = {
    enabled = true,        -- register avatar commands and allow the companion
    show_on_start = true,  -- restore the corner companion across sessions
    animations = true,     -- idle animations (blink, bounce, wave)
    transparent = true,    -- no background (shows through on transparent terminals)
  },
}
```

---

## 📜 License
Licensed under the [Apache License 2.0](LICENSE).
