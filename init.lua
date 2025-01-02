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
      file:write(vim.fn.json_encode {
        xp = 0,
        achievements = {},
        goals = {},
        date = {},
        lines_written = 0,
        total_time = 0,
        lvl = 0,
      })
      file:close()
    end
  end
end

function M.init()
  ensure_data_file()

  if storage.log_new_day() then
    logic.add_xp(10)
    ui.random_luck_popup()
    utils.calculate_all_lines_written()
    achievements.check_all_achievements()
  end

  vim.api.nvim_create_user_command('Gamify', function()
    ui.show_status_window(achievements.get_achievements_table_length())
  end, {})

  vim.api.nvim_create_user_command('LangStats', function()
    ui.show_languages_ui()
  end, {})

  vim.api.nvim_create_user_command('Achievements', function()
    ui.show_achievements()
  end, {})

  -- vim.api.nvim_create_autocmd('BufReadPost', {
  --   callback = function()
  --     logic.add_xp(5)
  --   end,
  -- })

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

  -- clear last entry after closing nvim
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      local data = storage.load_data()
      data.last_time_entry = nil
      storage.save_data(data)
      logic.add_total_time_spent()
    end,
  })
end

M.init()

return M
