local M = {}

local data_file = vim.fn.stdpath 'data' .. '/gamify/data.json'

function M.load_data()
  local file = io.open(data_file, 'r')
  if not file then
    return {
      xp = 0,
      achievements = {},
      goals = {},
      date = {},
      lines_written = 0,
      last_time_entry = os.date '%Y-%m-%d %H:%M:%S',
      total_time = 0,
      level = 0,
      time_spent = 0,
      code_nights = 0,
      code_mornings = 0,
      lines_written_in_specified_langs = {},
      errors_fixed = 0,
      day_streak = 0,
      commit_hashes = {},
    }
  end

  local content = file:read '*a'
  file:close()

  local data = vim.fn.json_decode(content)

  local defaults = {
    xp = 0,
    achievements = {},
    goals = {},
    date = {},
    lines_written = 0,
    last_time_entry = os.date '%Y-%m-%d %H:%M:%S',
    total_time = 0,
    level = 0,
    time_spent = 0,
    code_nights = 0,
    code_mornings = 0,
    lines_written_in_specified_langs = {},
    errors_fixed = 0,
    day_streak = 0,
    commit_hashes = {},
  }

  for k, v in pairs(defaults) do
    if data[k] == nil then
      data[k] = v
    end
  end

  return data
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
