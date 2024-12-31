local M = {}
local storage = require 'gamify.storage'
local config = require 'gamify.config'
local utils = require 'gamify.utils'

local user_data = storage.load_data()

function M.add_xp(amount)
  user_data.xp = (user_data.xp or 0) + amount
  storage.save_data(user_data)
end

function M.add_achievement(achievement)
  if not vim.tbl_contains(user_data.achievements, achievement) then
    table.insert(user_data.achievements, achievement)
    storage.save_data(user_data)
  end
end

function M.set_goal(description, deadline)
  table.insert(user_data.goals, { description = description, deadline = deadline })
  storage.save_data(user_data)
end

function M.set_time_entry()
  local data = storage.load_data()
  data.last_time_entry = os.date '%Y-%m-%d %H:%M:%S'
  storage.save_data(data)
end

function M.get_data()
  return user_data
end

-- time measured in seconds from last log to closing nvim
-- used only when nvim is closed
function M.add_total_time_spent()
  local last_log = M.get_data().last_time_entry
  local current_time = os.date '%Y%m%d %H:%M:%S'

  local time_diff = utils.check_hour_difference(current_time, last_log)
  local data = storage.load_data()
  data.total_time = data.total_time + time_diff
  storage.save_data(data)
end

function M.random_luck()
  if math.random(50) == 3 then
    local xp_amount = 50
    M.add_xp(xp_amount)
    local today_compliment = config.compliments[math.random(#config.compliments)]
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

  for added, file in string.gmatch(result, '(%d+)%s+%d+%s+(%S+)') do
    local lines_added = tonumber(added)
    local extension = file:match '^.+%.([a-zA-Z0-9]+)$' or 'unknown'
    local language = utils.get_file_language(extension) or 'Unknown'

    data.lines_written_in_specified_langs[language] = (data.lines_written_in_specified_langs[language] or 0) + lines_added

    -- print(string.format('Processed: %s (%s): %d lines added', file, language, lines_added))
  end

  table.insert(data.commit_hashes, new_commit_hash)

  storage.save_data(data)
end

return M
