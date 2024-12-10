local M = {}

local data_file = vim.fn.stdpath 'data' .. '/gamify/data.json'

function M.load_data()
  local file = io.open(data_file, 'r')
  if not file then
    return { xp = 0, achievements = {}, goals = {} } -- Default data
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

return M
