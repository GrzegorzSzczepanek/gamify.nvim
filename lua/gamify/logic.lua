local M = {}
local storage = require 'gamify.storage'
local utils = require 'gamify.utils'
local config = require 'gamify.config'

local function level_for_xp(xp)
  local lv = config.get().leveling
  return math.floor(1 + lv.A * (xp ^ lv.B))
end
M.level_for_xp = level_for_xp

function M.xp_for_level(level)
  local lv = config.get().leveling
  if level <= 1 then
    return 0
  end
  return ((level - 1) / lv.A) ^ (1 / lv.B)
end

-- opts.raw skips the prestige/focus multipliers for system rewards.
function M.add_xp(amount, achievement, opts)
  opts = opts or {}
  local data = storage.load_data()

  if achievement then
    data.achievements[achievement.name] = achievement.description
  end

  local multiplier = 1
  if not opts.raw then
    local prestige = data.prestige or 0
    multiplier = multiplier + prestige * config.get().prestige.xp_bonus_per_rank
    multiplier = multiplier * require('gamify.focus').current_multiplier()
  end

  local gained = math.floor(amount * multiplier + 0.5)
  data.xp = (data.xp or 0) + gained

  local today = os.date '%Y-%m-%d'
  data.daily_xp = data.daily_xp or {}
  data.daily_xp[today] = (data.daily_xp[today] or 0) + gained

  if config.get().ui.xp_popups and gained > 1 then
    vim.schedule(function()
      require('gamify.ui').show_xp_popup(gained)
    end)
  end

  local old_level = data.level or 1
  local new_level = level_for_xp(data.xp)

  if new_level > old_level then
    data.level = new_level
    local ui = require 'gamify.ui'
    ui.show_popup('LEVEL UP! You are now level ' .. new_level, 'Congratulations!', 'top_right')
    if config.get().ui.confetti then
      ui.show_falling_confetti(30, 3000)
    end
  end

  storage.save_data(data)
  return gained
end

local function add_xp_for_lines_written(lines)
  local per = config.get().xp.per_lines
  local xp = math.ceil(tonumber(lines) / per)
  M.add_xp(xp)
end

function M.set_goal(description, deadline)
  local data = storage.load_data()
  data.goals = data.goals or {}
  table.insert(data.goals, { description = description, deadline = deadline })
  storage.save_data(data)
end

function M.prestige()
  local data = storage.load_data()
  local cfg = config.get().prestige
  if not cfg.enabled then
    vim.notify('Prestige is disabled.', vim.log.levels.WARN, { title = 'Gamify' })
    return
  end
  local level = data.level or 1
  if level < cfg.level_required then
    vim.notify(
      string.format('You need level %d to prestige (currently %d).', cfg.level_required, level),
      vim.log.levels.WARN,
      { title = 'Gamify' }
    )
    return
  end

  vim.ui.input({ prompt = string.format('Prestige now? Resets XP for +%d%% permanent XP. Type YES: ', cfg.xp_bonus_per_rank * 100) }, function(input)
    if input ~= 'YES' then
      vim.notify('Prestige cancelled.', vim.log.levels.INFO, { title = 'Gamify' })
      return
    end
    local d = storage.load_data()
    d.prestige = (d.prestige or 0) + 1
    d.xp = 0
    d.level = 1
    storage.save_data(d)
    local ui = require 'gamify.ui'
    ui.show_popup('PRESTIGE ' .. d.prestige .. '! Permanent XP bonus increased.', 'Prestige', 'top_right')
    ui.show_falling_confetti(40, 4000)
  end)
end

function M.get_data()
  local data = storage.load_data()

  return data
end

-- used only when nvim is closed
function M.add_total_time_spent()
  local data = storage.load_data()
  local last_log = data.last_entry
  -- Use the actual current time when exiting Neovim
  local current_time = os.date('%Y-%m-%d %H:%M:%S')

  local time_diff = utils.check_hour_difference(last_log, current_time)
  if time_diff > 0 then
    data.total_time = (data.total_time or 0) + time_diff
    storage.save_data(data)
  end
end

function M.random_luck()
  if math.random(config.get().random_luck_chance) == 1 then
    M.add_xp(config.get().xp.random_luck)
    local today_compliment = utils.compliments[math.random(#utils.compliments)]
    return today_compliment
  end
  return nil
end

function M.track_lines()
  local data = storage.load_data()
  data.commit_hashes = data.commit_hashes or {}

  local is_git_repo = vim.fn.system('git rev-parse --is-inside-work-tree 2>/dev/null'):match 'true'
  if not is_git_repo then
    return
  end

  -- Check if there are any commits at all
  local has_commits = vim.fn.system('git rev-parse --verify HEAD 2>/dev/null') ~= ''
  if not has_commits then
    return
  end

  local new_commit_handle = io.popen 'git rev-parse HEAD 2>/dev/null'
  if not new_commit_handle then
    return
  end

  local new_commit_hash = new_commit_handle:read('*a'):gsub('%s+', '')
  new_commit_handle:close()

  if new_commit_hash == '' or vim.tbl_contains(data.commit_hashes, new_commit_hash) then
    return
  end

  -- Check if HEAD~1 exists
  local has_parent = vim.fn.system('git rev-parse --verify HEAD~1 2>/dev/null') ~= ''
  local diff_cmd = has_parent and 'git diff --numstat HEAD~1 HEAD 2>/dev/null' or 'git diff --numstat 4b825dc642cb6eb9a060e54bf8d69288fbee4904 HEAD 2>/dev/null'
  -- 4b825dc642cb6eb9a060e54bf8d69288fbee4904 is the hash of an empty tree

  local handle = io.popen(diff_cmd)
  if not handle then
    return
  end

  local result = handle:read '*a'
  handle:close()

  if not result or result == '' then
    return
  end

  local total_lines = 0
  for added, file in string.gmatch(result, '(%d+)%s+%d+%s+(%S+)') do
    local lines_added = tonumber(added)
    total_lines = total_lines + lines_added
    local extension = file:match '^.+%.([a-zA-Z0-9]+)$' or 'unknown'
    local language = utils.get_file_language(extension) or 'Unknown'

    data.lines_written_in_specified_langs[language] = (data.lines_written_in_specified_langs[language] or 0) + lines_added

    -- print(string.format('Processed: %s (%s): %d lines added', file, language, lines_added))
  end

  table.insert(data.commit_hashes, new_commit_hash)

  storage.save_data(data)

  add_xp_for_lines_written(tonumber(total_lines))
  require('gamify.quests').on_commit()
  if total_lines > 0 then
    require('gamify.quests').on_lines(total_lines)
  end
end

function M.track_keypress()
  local data = storage.load_data()
  local threshold = config.get().xp.per_keypresses
  data.keypress_count = (data.keypress_count or 0) + 1

  if data.keypress_count >= threshold then
    data.keypress_count = 0
    M.add_xp(1)
  end

  storage.save_data(data)
end

function M.get_role()
  local data = storage.load_data()
  local langs = data.lines_written_in_specified_langs or {}
  
  local max_lines = 0
  local dominant_lang = nil
  
  for lang, lines in pairs(langs) do
    if lines > max_lines then
      max_lines = lines
      dominant_lang = lang
    end
  end
  
  if not dominant_lang or max_lines == 0 then
    return "Novice Coder"
  end
  
  local roles = {
    ['JavaScript'] = "Frontend Wizard",
    ['TypeScript'] = "Frontend Wizard",
    ['JavaScript (React)'] = "Frontend Wizard",
    ['TypeScript (React)'] = "Frontend Wizard",
    ['HTML'] = "Frontend Wizard",
    ['CSS'] = "Frontend Wizard",
    ['Python'] = "Data Alchemist",
    ['C'] = "Systems Ninja",
    ['C++'] = "Systems Ninja",
    ['Rust'] = "Systems Ninja",
    ['Go'] = "Cloud Voyager",
    ['Lua'] = "Plugin Sorcerer",
    ['Vim Script'] = "Plugin Sorcerer",
    ['Shell'] = "Terminal Overlord",
  }
  
  return roles[dominant_lang] or (dominant_lang .. " Explorer")
end

function M.get_statusline_text()
  local data = storage.load_data()
  if not data then return "" end
  return string.format("Lvl %d 🔥 %d", data.level or 1, data.day_streak or 1)
end

-- e.g. "Lvl 12 [████░░] 🔥7"
function M.get_statusline_bar(bar_width)
  bar_width = bar_width or 6
  local data = storage.load_data()
  if not data then return '' end
  local level = data.level or 1
  local xp = data.xp or 0
  local cur = M.xp_for_level(level)
  local nxt = M.xp_for_level(level + 1)
  local progress = nxt > cur and (xp - cur) / (nxt - cur) or 0
  progress = math.max(0, math.min(1, progress))
  local filled = math.floor(progress * bar_width)
  local bar = string.rep('█', filled) .. string.rep('░', bar_width - filled)
  return string.format('Lvl %d [%s] 🔥%d', level, bar, data.day_streak or 1)
end

-- One clean-code payout per buffer per session, so `:w` can't farm XP.
local clean_code_awarded = {}

function M.check_clean_code()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })

  if #diagnostics ~= 0 then
    clean_code_awarded[bufnr] = nil
    return
  end

  if config.get().clean_code_once_per_buffer and clean_code_awarded[bufnr] then
    return
  end

  clean_code_awarded[bufnr] = true
  M.add_xp(config.get().xp.clean_code)
  require('gamify.quests').on_clean_code()
end

return M
