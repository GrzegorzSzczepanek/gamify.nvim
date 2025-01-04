local M = {}
local storage = require 'gamify.storage'
local utils = require 'gamify.utils'

-- A lower exponent B means it takes fewer XP to reach higher levels;
-- a smaller multiplier A also slows down level progression.
local A = 0.001
local B = 1.02

function M.add_xp(amount, achievement)
  -- print('add_xp called with amount:', amount)
  local data = storage.load_data()

  if achievement then
    data.achievements[achievement.name] = achievement.description
  end

  data.xp = (data.xp or 0) + amount

  local old_level = data.level or 1
  local new_level = math.floor(1 + A * (data.xp ^ B))

  if new_level > old_level then
    data.level = new_level
    -- print('Leveled up to:', new_level)
  end

  storage.save_data(data)
  -- print('XP after saving:', data.xp)
end

local function add_xp_for_lines_written(lines)
  -- print 'adding xp for lines'
  local xp = math.ceil(tonumber(lines) / 10)

  M.add_xp(xp)
end

function M.add_achievement(achievement)
  local data = storage.load_data()

  if not vim.tbl_contains(data.achievements, achievement) then
    table.insert(data.achievements, achievement)
    storage.save_data(data)
  end
end

function M.set_goal(description, deadline)
  local data = storage.load_data()

  table.insert(data.goals, { description = description, deadline = deadline })
  storage.save_data(data)
end

function M.set_time_entry()
  local data = storage.load_data()
  data.last_time_entry = storage.last_entry_format
  storage.save_data(data)
end

function M.get_data()
  local data = storage.load_data()

  return data
end

-- used only when nvim is closed
function M.add_total_time_spent()
  local data = storage.load_data()
  local last_log = data.last_entry
  local current_time = storage.last_entry_format

  -- print('Last log:', last_log)
  -- print('Current time:', current_time)

  local time_diff = utils.check_hour_difference(last_log, current_time)
  -- print('Time difference (hours):', time_diff)

  if time_diff > 0 then
    data.total_time = (data.total_time or 0) + time_diff
    storage.save_data(data)
  end
end

function M.random_luck()
  if math.random(40) == 1 then
    local xp_amount = 50
    M.add_xp(xp_amount)
    local today_compliment = utils.compliments[math.random(#utils.compliments)]
    return today_compliment
  end
  return nil
end

function M.track_lines()
  local data = storage.load_data()
  data.commit_hashes = data.commit_hashes or {}

  local new_commit_handle = io.popen 'git rev-parse HEAD'
  if not new_commit_handle then
    -- print 'Failed to get the latest commit hash.'
    return
  end

  local new_commit_hash = new_commit_handle:read('*a'):gsub('%s+', '')
  new_commit_handle:close()

  if vim.tbl_contains(data.commit_hashes, new_commit_hash) then
    -- print 'Commit already processed. Skipping...'
    return
  end

  local handle = io.popen 'git diff --numstat HEAD~1 HEAD'
  if not handle then
    -- print 'Failed to execute git diff.'
    return
  end

  local result = handle:read '*a'
  handle:close()

  if not result or result == '' then
    -- print 'No changes detected in git diff.'
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
end

return M
