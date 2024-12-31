local M = {}

local data_file = vim.fn.stdpath 'data' .. '/gamify/data.json'

-- json structure
-- {
-- xp = int
-- achievements = {} -- table of strings
-- goals = {} -- something like achievements but user sets them themself
-- date = {} -- days user opened nvim in
-- lines_of_code_written_in_nvim = {}
-- lines_in_specified_langs = {c: 123, cpp:4322, python:1243, rust: 123443}
-- last_time_entry date + time -- it's supposed to help with achievements for coding for few consecutive hours
-- total_time_in_nvim = 0 - in hours
-- code_nights = 0 -- times user spent more than 3 hours in editor between 11PM and 4AM
-- code_mornigs = 0 -- times users spent more than 3 hours in editor between 6AM and 11AM
-- errors_fixed = 0
-- day_streak = 0 -- streak in opening nvim in consecutive days
-- }
--

function M.load_data()
  local file = io.open(data_file, 'r')
  if not file then
    return {
      xp = 0,
      achievements = {
        ['Polyglot'] = '1000 lines in 10 languages',
        ['Jack of Many'] = '1000 lines in at least 5 different languages',
        ['Debug Master'] = 'Fix 20 errors in a single day',
        ['50 Shades of Debug'] = 'Fix 50 errors in a single day',
        ['Coding Deity'] = 'Fix 100 errors in a single day',
        ['Early Bird'] = 'Code for 3+ hours between 6AM and 11AM for 5 days',
        ['Marathon Coder'] = 'Code continuously for at least 5 hours',
        ['Two Thousand Lines'] = 'Write 2000 lines of code',
        ['Five Thousand Lines'] = 'Write 5000 lines of code',
        ['Ten Thousand Lines'] = 'Write 10000 lines of code',
        ['Weekly Streak'] = 'Open Neovim every day for 7 consecutive days',
        ['Two Weeks Streak'] = 'Open Neovim every day for 14 consecutive days',
        ['One Month Streak'] = 'Open Neovim every day for 30 consecutive days',
      },
      goals = {},
      date = {},
      lines_written = 0,
      last_time_entry = os.date '%Y-%m-%d %H:%M:%S',
      total_time = 0,
      lvl = 0,
      time_spent = 0,
      code_nights = 0,
      code_mornings = 0,
      lines_written_in_specified_langs = {},
      errors_fixed = 0,
      day_streak = 0,
      commit_hashes = {},
    } -- Default data
  end
  local content = file:read '*a'
  file:close()
  return vim.fn.json_decode(content)
end

function M.save_data(data)
  local file = io.open(data_file, 'w')
  if not file then
    error('Failed to open file for writing: ' .. data_file)
  end
  file:write(vim.fn.json_encode(data))
  file:close()
end

function M.get_last_day()
  local data = M.load_data()

  if data.date and type(data.date) == 'table' and #data.date > 0 then
    return data.date[#data.date]
  end

  return nil
end

function M.validate_time_entry(entry)
  if type(entry) == 'string' and entry:match '^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$' then
    return true
  end
  return false
end

function M.get_last_log()
  local data = M.load_data()
  local entry = data.last_time_entry

  if entry and M.validate_time_entry(entry) then
    return entry
  end
  return os.date '%Y%d%s %H:%m:%s'
end

-- it returns boolean so we can know if we should add exp to user for logging
function M.log_new_day()
  local current_date = os.date '%Y-%m-%d' -- Current date only
  local last_day_entry = M.get_last_day()

  -- Extract date part from last_time_entry if present
  local last_logged_date = last_day_entry and last_day_entry:match '%d%d%d%d%-%d%d%-%d%d' or nil

  -- Compare only the date part
  if last_logged_date ~= current_date then
    local data = M.load_data()
    data.date = data.date or {}
    table.insert(data.date, os.date '%Y-%m-%d %H:%M:%S')
    M.save_data(data)
    return true
  end

  return false
end

return M
