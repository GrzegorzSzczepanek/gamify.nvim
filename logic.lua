local M = {}
local storage = require 'gamify.storage'

local user_data = storage.load_data()

function M.add_xp(amount)
  user_data.xp = (user_data.xp or 0) + amount
  storage.save_data(user_data)
  return user_data.xp
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

function M.daily_nvim_launch()
  return 0
end

function M.calculate_daily_streak() end

function M.get_data()
  return user_data
end

return M
