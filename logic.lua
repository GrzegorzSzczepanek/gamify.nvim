-- String return statements are just placeholders for now until I find some satisfying way of showing info

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
  if math.random(4) == 3 then
    local xp_amount = 50
    M.add_xp(xp_amount)
    local today_compliment = config.compliments[math.random(#config.compliments)]
    return today_compliment
  end
  return nil
end

local function get_current_commit_hash()
  return vim.fn.system('git rev-parse HEAD'):gsub('\n', '')
end

local function get_git_added_lines()
  local output = vim.fn.system 'git diff --numstat HEAD'
  local lines = {}

  -- Match lines with added, deleted, and file columns
  for added, _, file in string.gmatch(output, '(%d+)%s+%d*%s+(.+)') do
    if file then
      local ext = file:match '^.+%.([a-zA-Z0-9]+)$'
      if ext then
        lines[ext] = (lines[ext] or 0) + tonumber(added)
      end
    end
  end

  return lines
end

function M.track_lines_on_save()
  local data = storage.load_data()
  local last_commit_hash = data.last_commit_hash or ''

  -- Run git diff to get added lines for the last commit
  local handle = io.popen('git diff --numstat ' .. last_commit_hash .. ' HEAD')
  if not handle then
    print 'Failed to execute git diff.'
    return
  end

  local result = handle:read '*a'
  handle:close()

  if not result or result == '' then
    print 'No changes detected in git diff.'
    return
  end

  -- Parse the git diff output
  for added, file in string.gmatch(result, '(%d+)%s+%d+%s+(%S+)') do
    local lines_added = tonumber(added)
    local extension = file:match '^.+%.([a-zA-Z0-9]+)$' or 'unknown'
    local language = utils.get_file_language(extension) or 'Unknown' -- Ensure extension_to_language_map is defined

    data.lines_written_in_specified_langs[language] = (data.lines_written_in_specified_langs[language] or 0) + lines_added
  end

  local new_commit_handle = io.popen 'git rev-parse HEAD'
  if not new_commit_handle then
    print 'Failed to get the new commit hash.'
    return
  end

  local new_commit_hash = new_commit_handle:read('*a'):gsub('%s+', '')
  new_commit_handle:close()

  if new_commit_hash and new_commit_hash ~= '' then
    data.last_commit_hash = new_commit_hash
  else
    print 'Failed to retrieve valid commit hash.'
  end

  storage.save_data(data)
end

return M
