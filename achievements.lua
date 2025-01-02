local M = {}

local storage = require 'gamify.storage'
local logic = require 'gamify.logic'
local utils = require 'gamify.utils'
local ui = require 'gamify.ui'

local function check_streak(days)
  local data = storage.load_data()
  if not data or type(data.date) ~= 'table' or #data.date < days then
    return false
  end

  local current_time = os.time()
  for i = 0, days - 1 do
    local expected_date = os.date('%Y-%m_%d', current_time - (i * 86000))
    if data.date[#data.date - days + 1 + i] ~= expected_date then
      return false
    end
  end

  return true
end

local function check_lines(lines_needed)
  local data = storage.load_data()
  return (data.lines_written or 0) >= lines_needed
end

local function lines_in_languages(num_of_langs, threshold)
  local data = storage.load_data()
  local lines_per_lang = data.lines_written_in_specified_langs or {}
  local count_above_threshold = 0

  for _, lines in pairs(lines_per_lang) do
    if lines >= threshold then
      count_above_threshold = count_above_threshold + 1
    end
  end

  return count_above_threshold == num_of_langs
end

local function check_fixed_errors_in_a_day(number_of_errors)
  local todays_timelog = storage.get_last_log() or os.date '%Y-%m-%d %H:%M:%S'
  local current_date = os.date '%Y-%m-%d %H:%M:%S'

  if type(todays_timelog) == 'string' and type(current_date) == 'string' then
    local timelog_date_only = string.sub(todays_timelog, 1, 10)
    local current_date_only = string.sub(current_date, 1, 10)
    if timelog_date_only == current_date_only then
      local data = logic.get_data()
      return (data.errors_fixed or 0) >= number_of_errors
    end
  end
  return false
end

local achievement_definitions = {
  {
    name = 'Weekly Streak',
    description = 'Open Neovim every day for 7 consecutive days',
    xp = 500,
    check = function()
      return check_streak(7)
    end,
  },
  {
    name = 'Two Weeks Streak',
    description = 'Open Neovim every day for 14 consecutive days',
    xp = 1500,
    check = function()
      return check_streak(14)
    end,
  },
  {
    name = 'One Month Streak',
    description = 'Open Neovim every day for 30 consecutive days',
    xp = 4000,
    check = function()
      return check_streak(30)
    end,
  },

  {
    name = 'Hundred lines',
    description = 'Write 100 lines of code',
    xp = 100,
    check = function()
      return check_lines(100)
    end,
  },
  {
    name = 'Thousand Lines',
    description = 'Write 1000 lines of code',
    xp = 150,
    check = function()
      return check_lines(1000)
    end,
  },
  {
    name = 'Two Thousand Lines',
    description = 'Write 2000 lines of code',
    xp = 350,
    check = function()
      return check_lines(2000)
    end,
  },
  {
    name = 'Five Thousand Lines',
    description = 'Write 5000 lines of code',
    xp = 600,
    check = function()
      return check_lines(5000)
    end,
  },
  {
    name = 'Ten Thousand Lines',
    description = 'Write 10000 lines of code',
    xp = 800,
    check = function()
      return check_lines(10000)
    end,
  },
  {
    name = 'Twenty Five Thousand Lines',
    description = 'Write 25000 lines of code',
    xp = 2000,
    check = function()
      return check_lines(25000)
    end,
  },

  {
    name = 'Night Owl',
    description = 'Code for at least 3 hours between 11PM and 4AM five times',
    xp = 1000,
    check = function()
      local data = storage.load_data()
      return (data.code_nights or 0) == 4
    end,
  },

  {
    name = 'Early Bird',
    description = 'Code for at least 3 hours between 6AM and 11AM five times',
    xp = 1000,
    check = function()
      local data = storage.load_data()
      return (data.code_mornings or 0) == 4
    end,
  },

  {
    name = 'Jack of Many',
    description = 'Write at least 1000 lines in more than 5 languages',
    xp = 2500,
    check = function()
      return lines_in_languages(5, 1000)
    end,
  },
  {
    name = 'Polyglot',
    description = 'Write at least 1000 lines in more than 10 languages',
    xp = 5000,
    check = function()
      return lines_in_languages(10, 1000)
    end,
  },

  {
    name = 'Marathoner',
    description = 'Code continuously for at least 6 hours',
    xp = 1800,
    check = function()
      local last_day = storage.get_last_day()
      if not last_day then
        return false
      end

      local last_day_table = utils.parse_time(last_day)
      if not last_day_table then
        return false
      end

      local start_time = os.time(last_day_table)
      local current_time = os.time()
      local time_diff = os.difftime(current_time, start_time)

      return (time_diff / 3600) >= 6
    end,
  },

  {
    name = 'Debug Master',
    description = 'Fix 20 errors in a single day',
    xp = 500,
    check = function()
      return check_fixed_errors_in_a_day(20)
    end,
  },
  {
    name = '50 Shades of Debugging',
    description = 'Fix 50 errors in a single day',
    xp = 1500,
    check = function()
      return check_fixed_errors_in_a_day(50)
    end,
  },
  {
    name = 'Coding Deity',
    description = 'Fix 100 errors in a single day',
    xp = 4000,
    check = function()
      return check_fixed_errors_in_a_day(100)
    end,
  },
}

function M.get_achievements_table_length()
  return utils.get_table_length(achievement_definitions)
end

function M.check_all_achievements()
  local data = storage.load_data()

  for _, achievement in ipairs(achievement_definitions) do
    local already_unlocked = data.achievements[achievement.name] ~= nil
    local meets_requirement = achievement.check()

    if meets_requirement and not already_unlocked then
      logic.add_xp(achievement.xp, achievement)
      ui.show_achievement_popup(achievement.name)
    end
  end
end

function M.track_error_fixes()
  local previous_error_count = 0

  vim.api.nvim_create_autocmd({ 'TextChanged', 'BufWritePost' }, {
    callback = function()
      local diagnostics = vim.diagnostic.get(0)
      local current_error_count = 0

      for _, diag in ipairs(diagnostics) do
        if diag.severity == vim.diagnostic.severity.ERROR then
          current_error_count = current_error_count + 1
        end
      end

      if current_error_count < previous_error_count then
        local resolved_errors = previous_error_count - current_error_count
        local data = storage.load_data()
        data.errors_fixed = (data.errors_fixed or 0) + resolved_errors
        storage.save_data(data)
      end

      previous_error_count = current_error_count
    end,
  })
end

return M
