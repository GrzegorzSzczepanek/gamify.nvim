local M = {}

local data_file = vim.fn.stdpath 'data' .. '/gamify/data.json'
local ui = require 'gamify.ui'
local logic = require 'gamify.logic'
local storage = require 'gamify.storage'
local achievements = require 'gamify.achievements'
local utils = require 'gamify.utils'

local function ensure_data_file()
  local data_dir = vim.fn.stdpath 'data' .. '/gamify'

  if vim.fn.isdirectory(data_dir) == 0 then
    vim.fn.mkdir(data_dir, 'p')
  end

  if vim.fn.filereadable(data_file) == 0 then
    local file = io.open(data_file, 'w')
    if file then
      file:write(vim.fn.json_encode(storage.data_json_format))
      file:close()
    end
  end
end

function M.setup()
  -- M.setup gets called when the plugin gets required by eg. user's package manager
  ensure_data_file()

  local data = storage.load_data()
  data.last_entry = os.date('%Y-%m-%d %H:%M:%S')
  storage.save_data(data)

  if storage.log_new_day() then
    logic.add_xp(10)
    ui.random_luck_popup()
    utils.calculate_all_lines_written()
    utils.check_streak()
    achievements.check_all_achievements()
  end

  vim.api.nvim_create_user_command('Gamify', function()
    data.gamify_cmd_count = data.gamify_cmd_count + 1
    achievements.check_all_achievements()
    ui.show_status_window(achievements.get_achievements_table_length())
  end, {})

  vim.api.nvim_create_user_command('LangStats', function()
    ui.show_languages_ui()
  end, {})

  vim.api.nvim_create_user_command('Achievements', function()
    ui.show_achievements()
  end, {})

  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*',
    callback = function()
      ui.random_luck_popup()
      logic.track_lines()
      achievements.track_error_fixes()
      utils.calculate_all_lines_written()
      achievements.check_all_achievements()
    end,
  })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      logic.add_total_time_spent()
      utils.track_night_coding()
      utils.track_morning_coding()

      data = storage.load_data()
      data.last_entry = nil
      storage.save_data(data)
    end,
  })
end

M.setup()

return M
