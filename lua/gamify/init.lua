local M = {}

local data_file = vim.fn.stdpath 'data' .. '/gamify/data.json'
local config = require 'gamify.config'
local ui = require 'gamify.ui'
local logic = require 'gamify.logic'
local storage = require 'gamify.storage'
local achievements = require 'gamify.achievements'
local utils = require 'gamify.utils'
local quests = require 'gamify.quests'
local focus = require 'gamify.focus'

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

local function register_commands()
  vim.api.nvim_create_user_command('Gamify', function()
    local data = storage.load_data()
    data.gamify_cmd_count = (data.gamify_cmd_count or 0) + 1
    storage.save_data(data)
    achievements.check_all_achievements()
    ui.show_status_window(achievements.get_achievements_table_length())
  end, {})

  vim.api.nvim_create_user_command('LangStats', function()
    ui.show_languages_ui()
  end, {})

  vim.api.nvim_create_user_command('Achievements', function()
    ui.show_achievements()
  end, {})

  vim.api.nvim_create_user_command('GamifySnake', function()
    require('gamify.games').start_snake()
  end, {})

  vim.api.nvim_create_user_command('GamifyChallenges', function()
    require('gamify.challenges').show_challenges_menu()
  end, {})

  vim.api.nvim_create_user_command('GamifySaper', function()
    require('gamify.games').start_minesweeper()
  end, {})

  vim.api.nvim_create_user_command('GamifySudoku', function()
    require('gamify.games').start_sudoku()
  end, {})

  vim.api.nvim_create_user_command('Gomoku', function(args)
    local gomoku = require 'gamify.gomoku'
    local sub = args.fargs[1]
    if sub == 'host' then
      gomoku.host(args.fargs[2])
    elseif sub == 'join' then
      gomoku.join(args.fargs[2], args.fargs[3])
    else
      gomoku.start_local()
    end
  end, {
    nargs = '*',
    complete = function(_, line)
      if line:match '%sGomoku%s+%S*$' then
        return { 'host', 'join' }
      end
      return {}
    end,
  })

  vim.api.nvim_create_user_command('GamifyHeatmap', function()
    ui.show_heatmap()
  end, {})

  vim.api.nvim_create_user_command('GamifyAvatar', function(args)
    local avatar = require 'gamify.avatar'
    local sub = args.fargs[1]
    if sub == 'show' then
      avatar.set_enabled(true)
    elseif sub == 'hide' then
      avatar.set_enabled(false)
    elseif sub == 'toggle' then
      local on = avatar.toggle()
      vim.notify('Avatar ' .. (on and 'shown' or 'hidden'), vim.log.levels.INFO, { title = 'Gamify' })
    elseif sub == 'anim' then
      avatar.set_animations(args.fargs[2] ~= 'off')
    elseif sub == 'corner' then
      avatar.set_corner(args.fargs[2])
    else -- default / 'edit' / 'create' open the generator
      avatar.open_generator()
    end
  end, {
    nargs = '*',
    complete = function(_, line)
      if line:match '%scorner%s+%S*$' then
        return { 'top_left', 'top_right', 'bottom_left', 'bottom_right' }
      elseif line:match '%sanim%s+%S*$' then
        return { 'on', 'off' }
      elseif line:match '%sGamifyAvatar%s+%S*$' then
        return { 'edit', 'show', 'hide', 'toggle', 'anim', 'corner' }
      end
      return {}
    end,
  })

  vim.api.nvim_create_user_command('GamifyShare', function()
    ui.show_share_card()
  end, {})

  vim.api.nvim_create_user_command('GamifyStats', function()
    local data = storage.load_data()
    local lvl = data.level or 1
    vim.notify(
      string.format(
        'Gamify: Lvl %d | XP %d | %d lines | %d commits | streak %d | prestige %d',
        lvl,
        math.floor(data.xp or 0),
        data.lines_written or 0,
        #(data.commit_hashes or {}),
        data.day_streak or 1,
        data.prestige or 0
      ),
      vim.log.levels.INFO,
      { title = 'Gamify' }
    )
  end, {})

  vim.api.nvim_create_user_command('GamifyPrestige', function()
    logic.prestige()
  end, {})

  vim.api.nvim_create_user_command('GamifyReset', function()
    vim.ui.input({ prompt = 'Type RESET to wipe all Gamify progress: ' }, function(input)
      if input == 'RESET' then
        storage.save_data(vim.deepcopy(storage.data_json_format))
        vim.notify('Gamify progress has been reset.', vim.log.levels.WARN, { title = 'Gamify' })
      else
        vim.notify('Reset cancelled.', vim.log.levels.INFO, { title = 'Gamify' })
      end
    end)
  end, {})
end

local function register_autocommands()
  local group = vim.api.nvim_create_augroup('Gamify', { clear = true })

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*',
    callback = function()
      ui.random_luck_popup()
      logic.track_lines()
      achievements.track_error_fixes()
      utils.calculate_all_lines_written()
      quests.on_save()
      achievements.check_all_achievements()
      logic.check_clean_code()
    end,
  })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function()
      logic.track_keypress()
      focus.tick()
    end,
  })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      logic.add_total_time_spent()
      utils.track_night_coding()
      utils.track_morning_coding()
      focus.flush()
    end,
  })
end

function M.setup(opts)
  config.setup(opts)

  ensure_data_file()

  local data = storage.load_data()
  data.last_entry = os.date '%Y-%m-%d %H:%M:%S'
  storage.save_data(data)

  if storage.log_new_day() then
    logic.add_xp(config.get().xp.new_day)
    ui.random_luck_popup()
    utils.calculate_all_lines_written()
    utils.check_streak()
    quests.generate_for_today()
    achievements.check_all_achievements()
  else
    quests.generate_for_today()
  end

  register_commands()
  register_autocommands()

  if config.get().avatar.enabled and config.get().avatar.show_on_start then
    require('gamify.avatar').restore()
  end
end

return M
