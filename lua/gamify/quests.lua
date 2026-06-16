local M = {}

local storage = require 'gamify.storage'
local config = require 'gamify.config'

local quest_pool = {
  { id = 'lines_150', type = 'lines', target = 150, xp = 80, description = 'Write 150 lines of code' },
  { id = 'lines_300', type = 'lines', target = 300, xp = 150, description = 'Write 300 lines of code' },
  { id = 'commits_2', type = 'commits', target = 2, xp = 100, description = 'Make 2 commits' },
  { id = 'commits_5', type = 'commits', target = 5, xp = 200, description = 'Make 5 commits' },
  { id = 'clean_3', type = 'clean_code', target = 3, xp = 90, description = 'Save 3 files with zero errors' },
  { id = 'fix_3', type = 'errors', target = 3, xp = 120, description = 'Fix 3 diagnostic errors' },
  { id = 'kata_1', type = 'kata', target = 1, xp = 150, description = 'Complete 1 coding kata' },
  { id = 'game_1', type = 'game', target = 1, xp = 80, description = 'Play a mini-game' },
}

local function today()
  return os.date '%Y-%m-%d'
end

local function pick_quests(count)
  local pool = vim.deepcopy(quest_pool)

  -- Seed from the date so the same quests are picked all day, then restore
  -- entropy so the rest of the session's math.random isn't deterministic.
  local seed = 0
  for _, b in ipairs { today():byte(1, -1) } do
    seed = seed + b
  end
  math.randomseed(seed)
  for i = #pool, 2, -1 do
    local j = math.random(i)
    pool[i], pool[j] = pool[j], pool[i]
  end
  math.randomseed(os.time())

  local picked = {}
  for i = 1, math.min(count, #pool) do
    local q = pool[i]
    table.insert(picked, {
      id = q.id,
      type = q.type,
      target = q.target,
      xp = q.xp,
      description = q.description,
      progress = 0,
      done = false,
    })
  end
  return picked
end

function M.generate_for_today()
  if not config.get().quests.enabled then
    return
  end
  local data = storage.load_data()
  data.quests = data.quests or { date = nil, active = {}, bonus_claimed = false }

  if data.quests.date ~= today() then
    data.quests.date = today()
    data.quests.active = pick_quests(config.get().quests.count)
    data.quests.bonus_claimed = false
    storage.save_data(data)
  end
end

local function progress(qtype, amount)
  if not config.get().quests.enabled then
    return
  end
  local data = storage.load_data()
  local q = data.quests
  if not q or q.date ~= today() or type(q.active) ~= 'table' then
    return
  end

  local logic = require 'gamify.logic'
  local ui = require 'gamify.ui'
  local changed = false

  for _, quest in ipairs(q.active) do
    if quest.type == qtype and not quest.done then
      quest.progress = math.min(quest.target, quest.progress + amount)
      changed = true
      if quest.progress >= quest.target then
        quest.done = true
        storage.save_data(data)
        logic.add_xp(quest.xp)
        if config.get().ui.popups then
          ui.show_popup('Quest complete: ' .. quest.description .. ' (+' .. quest.xp .. ' XP)', 'Daily Quest', 'bottom_left')
        end
        -- add_xp wrote its own copy; re-read so later saves don't clobber it
        data = storage.load_data()
        q = data.quests
      end
    end
  end

  if changed then
    storage.save_data(data)
  end

  if not q.bonus_claimed and #q.active > 0 then
    local all_done = true
    for _, quest in ipairs(q.active) do
      if not quest.done then
        all_done = false
        break
      end
    end
    if all_done then
      data = storage.load_data()
      data.quests.bonus_claimed = true
      storage.save_data(data)
      logic.add_xp(config.get().quests.completion_bonus)
      if config.get().ui.popups then
        ui.show_popup('All daily quests cleared! +' .. config.get().quests.completion_bonus .. ' bonus XP', 'Daily Quests', 'top_right')
      end
      if config.get().ui.confetti then
        ui.show_falling_confetti(25, 2500)
      end
    end
  end
end

function M.on_lines(n)
  progress('lines', n)
end

function M.on_commit()
  progress('commits', 1)
end

function M.on_clean_code()
  progress('clean_code', 1)
end

function M.on_errors_fixed(n)
  progress('errors', n)
end

function M.on_kata()
  progress('kata', 1)
end

function M.on_game()
  progress('game', 1)
end

function M.on_save() end

function M.get_active()
  local data = storage.load_data()
  if data.quests and data.quests.date == today() then
    return data.quests.active or {}
  end
  return {}
end

return M
