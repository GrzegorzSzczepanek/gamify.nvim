local M = {}

local data_file = vim.fn.stdpath 'data' .. '/gamify/data.json'

-- json structure
-- {
-- xp = int
-- achievements = {}
-- goals = {}
-- date = {}
-- }

function M.load_data()
  local file = io.open(data_file, 'r')
  if not file then
    return { xp = 0, achievements = {}, goals = {}, date = {} } -- Default data
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

function M.log_new_day()
  local current_date = os.date '%Y-%m-%d'
  local last_day_entry = M.get_last_day()

  if current_date ~= last_day_entry then
    local data = M.load_data()
    data.date = data.date or {}
    table.insert(data.date, current_date)
    M.save_data(data)
  end
end

return M
