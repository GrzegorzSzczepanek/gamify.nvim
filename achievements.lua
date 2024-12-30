local M = {}

local storage = require 'gamify.storage'
local logic = require 'gamify.logic'
local utils = require 'gamify.utils'

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
  if check_streak(7) then
    local data = storage.load_data()
    data.achievements['Weekly Streak'] = 'Open Neovim every day for 7 consecutive days'
    storage.save_data(data)
  end
end

function M.two_weeks_streak()
  logic.add_xp(1500)
  if check_streak(14) then
    local data = storage.load_data()
    data.achievements['Two Weeks Streak'] = 'Open Neovim every day for 14 consecutive days'
    storage.save_data(data)
  end
end

function M.month_streak()
  logic.add_xp(4000)
  if check_streak(30) then
    local data = storage.load_data()
    data.achievements['One Month Streak'] = 'Open Neovim every day for 30 consecutive days'
    storage.save_data(data)
  end
end

local function check_lines(lines)
  local data = storage.load_data()
  return data.lines_written and data.lines_written >= lines
end

function M.thousand_lines()
  logic.add_xp(150)
  if check_lines(1000) then
    local data = storage.load_data()
    data.achievements['Thousand Lines'] = 'Write 1000 lines of code'
    storage.save_data(data)
  end
end

function M.two_thousand_lines()
  logic.add_xp(350)
  if check_lines(2000) then
    local data = storage.load_data()
    data.achievements['Two Thousand Lines'] = 'Write 2000 lines of code'
    storage.save_data(data)
  end
end

function M.five_thousand_lines()
  logic.add_xp(600)
  if check_lines(5000) then
    local data = storage.load_data()
    data.achievements['Five Thousand Lines'] = 'Write 5000 lines of code'
    storage.save_data(data)
  end
end

function M.ten_thousand_lines()
  logic.add_xp(800)
  if check_lines(10000) then
    local data = storage.load_data()
    data.achievements['Ten Thousand Lines'] = 'Write 10000 lines of code'
    storage.save_data(data)
  end
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
        data.achievements['Night Owl'] = 'Code for at least 3 hours between 11PM and 4AM five times'
        storage.save_data(data)
        logic.add_xp(1000)
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
        data.achievements['Early Bird'] = 'Code for at least 3 hours between 6AM and 11AM five times'
        storage.save_data(data)
        logic.add_xp(1000)
      end
    end
  end
end

local function lines_in_langues(num_of_langs, threshold)
  local data = storage.load_data()
  local lines_per_lang = data.lines_written_in_specified_langs
  local number_of_lines_above_threshold = 0
  for _, lines in pairs(lines_per_lang) do
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
  if lines_in_langues(5, 1000) then
    local data = storage.load_data()
    data.achievements['Jack of Many'] = 'Write at least 1000 lines in more than 5 languages'
    storage.save_data(data)
    logic.add_xp(2500)
  end
end

function M.polyglot()
  if lines_in_langues(10, 1000) then
    local data = storage.load_data()
    data.achievements['Polyglot'] = 'Write at least 1000 lines in more than 10 languages'
    storage.save_data(data)
    logic.add_xp(5000)
  end
end

-- Code for at least 6 h without closing nvim
function M.marathon_coder()
  local start_time = os.time(storage.get_last_day()) or os.date '%Y-%m-%d %H:%M:%S'
  local current_date = os.date '%Y-%m-%d %H:%M:%S'

  local time_diff = utils.check_hour_difference(current_date, start_time)
  if time_diff >= 6 then
    local data = storage.load_data()
    data.achievements['Marathoner'] = 'Code continuously for at least 6 hours'
    storage.save_data(data)
    logic.add_xp(1800)
  end
end

function M.fixed_errors(number_of_errors)
  local data = logic.get_data()
  if data.errors_fixed >= number_of_errors then
    return true
  end

  return false
end

function M.check_error_fixes_in_a_day(number_of_errors)
  local todays_timelog = storage.get_last_log() or os.date '%Y-%m-%d %H:%M:%S'
  local current_date = os.date '%Y-%m-%d %H:%M:%S'

  if type(todays_timelog) == 'string' and type(current_date) == 'string' then
    -- extracting the date part
    local timelog_date_only = string.sub(todays_timelog, 1, 10)
    local current_date_only = string.sub(current_date, 1, 10)

    if timelog_date_only == current_date_only and M.fixed_errors(number_of_errors) then
      return true
    end
  end
  return nil
end

function M.debug_master()
  if M.check_error_fixes_in_a_day(20) then
    local data = storage.load_data()
    data.achievements['Debug Master'] = 'Fix 20 errors in a single day'
    storage.save_data(data)
    logic.add_xp(500)
  end
end

function M.fifty_shades_of_debug()
  if M.check_error_fixes_in_a_day(50) then
    local data = storage.load_data()
    data.achievements['50 Shades of Debugging'] = 'Fix 50 errors in a single day'
    storage.save_data(data)
    logic.add_xp(1500)
  end
end

function M.coding_deity()
  if M.check_error_fixes_in_a_day(100) then
    local data = storage.load_data()
    data.achievements['Coding Deity'] = 'Fix 100 errors in a single day'
    storage.save_data(data)
    logic.add_xp(4000)
  end
end

function M.track_error_fixes()
  vim.api.nvim_create_autocmd({ 'TextChanged', 'BufWritePost' }, {
    callback = function()
      local diagnostics = vim.diagnostic.get(0)
      local has_errors = false

      for _, diag in ipairs(diagnostics) do
        if diag.severity == vim.diagnostic.severity.ERROR then
          has_errors = true
          break
        end
      end

      if not has_errors then
        local data = storage.load_data()
        local errors_fixed = (data.errors_fixed or 0) + 1
        if errors_fixed >= 20 and errors_fixed < 50 then
          M.debug_master()
        elseif errors_fixed >= 50 and errors_fixed < 100 then
          if not data.achievements['Debug Master'] then
            M.debug_master()
          end
          M.fifty_shades_of_debug()
        elseif data.errors_fixed >= 100 then
          if not data.achievements['Debug Master'] then
            M.debug_master()
          end
          if not data.achievements['50 Shades of Debug'] then
            M.fifty_shades_of_debug()
          end
          M.coding_deity()
        end
      end
    end,
  })
end

return M
