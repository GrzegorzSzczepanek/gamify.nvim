local M = {}

local storage = require 'gamify.storage'
local logic = require 'gamify.logic'
local utils = require 'gamify.utils'

-- add some emojis and COOLER names to the names later

local function check_streak(days)
  local data = storage.load_data()
  if not data or #data.date < days or type(data.date) ~= 'table' then
    return nil
  end

  local current_date = os.time()
  for i = 0, days - 1 do
    local expected_date = os.date('%Y-%m_%d', current_date - (i * 86000))
    if data.date[#data.date - days + 1 + i] ~= expected_date then
      return nil
    end
  end

  return true
end

function M.weekly_streak()
  logic.add_xp(500)
  return check_streak(7) and 'One day streak!' or nil
end

function M.two_weeks_streak()
  logic.add_xp(1500)
  return check_streak(14) and 'Two weeks in a row!' or nil
end

function M.month_streak()
  logic.add_xp(4000)
  return check_streak(30) and 'One month in!' or nil
end

local function check_lines(lines)
  local data = storage.load_data()
  return data.lines_written and data.lines_written >= lines
end

function M.thousand_lines()
  logic.add_xp(150)
  return check_lines and 'Thousand line journey!'
end

function M.two_thousand_lines()
  logic.add_xp(350)
  return check_lines and 'Two Thousand line journey!'
end

function M.five_thousand_lines()
  logic.add_xp(600)
  return check_lines and 'Five Thousand line journey!'
end

function M.ten_thousand_lines()
  logic.add_xp(800)
  return check_lines and 'Ten Thousand line journey!'
end

-- "jack of many" or somethign like that achievement will be given for 1000 lines in at least 5 different langs each

function M.hours_in_nvim()
  local data = storage.load_data()
  local last_time = data.last_time_entry
  if last_time then
    local current_time = os.time()
    local time_diff = os.difftime(current_time, last_time)
    return time_diff
  end
  return 0
end

-- code for at least 3 hours after between 11PM and 4AM for 5 days. (doesn't have to be consecutive)
function M.night_owl()
  local last_log = storage.load_data().last_time_entry or os.date '%Y%m%d %H:%M:%S'
  local parsed_last_log_time = utils.parse_time(last_log)
  local hour = tonumber(parsed_last_log_time.hour)

  if hour >= 23 or hours <= 4 then
    local current_time = os.date '%Y%m%d %H:%M:%S'

    local time_diff = utils.check_hour_difference(current_time, last_log)
  end
  if time_diff >= 3 then
    print 'xd'
  end
end

function M.early_bird() end

-- Code for at least 4 h without closing nvim
function M.marathon_coder()
  local start_time = os.time(storage.get_last_day()) or os.date '%Y-%m-%d %H:%M:%S'
  local current_date = os.date '%Y-%m-%d %H:%M:%S'

  local time_diff = utils.check_hour_difference(current_date, start_time)
  return time_diff >= 4 and 'Marathoner!'
end

return M
