-- String return statements are just placeholders for now until I find some satisfying way of showing info

local M = {}
local storage = require 'gamify.storage'
local config = require 'gamify.config'

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
  local log_time = M.get_data().last_time_entry
  local current_time = os.date '%Y%m%d %H:%M:%S'
end

-- I shuold have some compliment dict and pick random one to show in notification
function M.random_luck()
  if math.random(4) == 3 then
    local xp_amount = 50
    M.add_xp(xp_amount)
    local today_compliment = config.compliments(math.random(#config.compliments))
    return today_compliment .. ' \nYou receive' .. xp_amount
  end
  return nil
end

return M
