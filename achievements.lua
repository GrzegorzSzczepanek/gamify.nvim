-- TODO achievements should have their table in storage and instead results we should get popup and insert to table and update user data

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
  local data = storage.load_data()
  local last_log = data.last_time_entry or os.date '%Y%m%d %H:%M:%S'
  local parsed_last_log_time = utils.parse_time(last_log)
  local hour = tonumber(parsed_last_log_time.hour)

  if hour >= 23 or hour <= 4 then
    local current_time = os.date '%Y%m%d %H:%M:%S'
    local time_diff = utils.check_hour_difference(current_time, last_log)
    if time_diff >= 3 then
      data.code_nights = (data.code_nights or 0) + 1
      storage.save_data(data)
      if data.code_nights == 4 then
        return 'Achievement for night owl idk'
      end
    end
  end
end

function M.early_bird()
  local data = storage.load_data()
  local last_log = data.last_time_entry or os.date '%Y%m%d %H:%M:%S'
  local parsed_last_log_time = utils.parse_time(last_log)
  local hour = tonumber(parsed_last_log_time.hour)

  if hour >= 6 or hour <= 11 then
    local current_time = os.date '%Y%m%d %H:%M:%S'
    local time_diff = utils.check_hour_difference(current_time, last_log)
    if time_diff >= 3 then
      data.code_mornings = (data.code_mornings or 0) + 1
      storage.save_data(data)
      if data.code_mornings == 4 then
        return 'Achievement for night owl idk'
      end
    end
  end
end

function M.lines_in_langues(num_of_langs, threshold)
  local data = storage.load_data()
  local lines_per_lang = data.lines_written_in_specified_langs
  local number_of_lines_above_threshold = 0
  for language, lines in pairs(lines_per_lang) do
    if lines >= threshold then
      number_of_lines_above_threshold = (number_of_lines_above_threshold or 0) + 1
    end
  end
  if number_of_lines_above_threshold == num_of_langs then
    return true
  end
  return false
end

function M.jack_of_many()
  if M.lines_in_langues(5, 1000) then
    return 'SOMETHIGN For at least 1000 lines in more than 5 langues'
  end
end

function M.polyglot()
  if M.lines_in_langues(5, 1000) then
    return 'SOMETHIGN For at least 1000 lines in more than 10 langues'
  end
end

-- Code for at least 5 h without closing nvim
function M.marathon_coder()
  local start_time = os.time(storage.get_last_day()) or os.date '%Y-%m-%d %H:%M:%S'
  local current_date = os.date '%Y-%m-%d %H:%M:%S'

  local time_diff = utils.check_hour_difference(current_date, start_time)
  return time_diff >= 5 and 'Marathoner!'
end

function M.fixed_errors(number_of_errors)
  local data = logic.get_data()
  if data.errors_fixed >= number_of_errors then
    return true
  end

  return false
end

--
function M.check_error_fixes_in_a_day(number_of_errors)
  local todays_timelog = storage.get_last_log() or os.date '%Y-%m-%d %H:%M:%S'
  local current_date = os.date '%Y-%m-%d %H:%M:%S'

  if type(todays_timelog) == 'string' and type(current_date) == 'string' then
    -- extracting the date part
    local timelog_date_only = string.sub(todays_timelog, 1, 10)
    local current_date_only = string.sub(current_date, 1, 10)

    if timelog_date_only == current_date_only and M.fixed_errors(number_of_errors) then
      return 'debug done'
    end
  end
  return nil
end

-- fix 20 errors in a day
function M.debug_master()
  return M.check_error_fixes_in_a_day(20) and 'Debug master'
end

-- fix 50 errors in a day
function M.fifty_shades_of_debug()
  return M.check_error_fixes_in_a_day(50) and '50 Shades of Debugging'
end

-- 100 bugs per day fixed
function M.coding_deity()
  return M.check_error_fixes_in_a_day(100) and 'Debigging deity.'
end

return M
