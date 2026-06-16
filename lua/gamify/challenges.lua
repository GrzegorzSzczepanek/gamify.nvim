local M = {}
local logic = require 'gamify.logic'
local katas = require 'gamify.katas'
local storage = require 'gamify.storage'

local challenges = katas.list

local function is_completed(data, id)
  return data.completed_katas and data.completed_katas[tostring(id)] == true
end

function M.show_challenges_menu()
  local daily = katas.daily_id()
  local data = storage.load_data()
  local width = 56
  local height = #challenges + 8
  local buf = vim.api.nvim_create_buf(false, true)

  local lines = { '  🏆 GAMIFY KATAS 🏆', '' }
  for i, c in ipairs(challenges) do
    local mark = is_completed(data, c.id) and '✔' or ' '
    local star = (c.id == daily) and ' ⭐(daily +50%)' or ''
    table.insert(lines, string.format('  [%s] %d. %s (%d XP)%s', mark, i, c.title, c.xp, star))
  end
  table.insert(lines, '')
  table.insert(lines, '  Select a number to start')
  table.insert(lines, '  (b) Back to Dashboard  (q) Quit')

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
  })

  for i = 1, #challenges do
    vim.keymap.set('n', tostring(i), function()
      vim.api.nvim_win_close(win, true)
      M.start_challenge(challenges[i])
    end, { buffer = buf })
  end

  vim.keymap.set('n', 'b', function()
    vim.api.nvim_win_close(win, true)
    require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buf })

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

function M.start_challenge(challenge)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'lua')

  local header = {
    '-- 🎯 Challenge: ' .. challenge.title,
    '-- 📝 Description: ' .. challenge.description,
    '-- 🚀 Press <Enter> to run tests | <Esc> to quit',
    '',
  }
  vim.list_extend(header, vim.split(challenge.initial_code, '\n'))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = 80,
    height = 20,
    row = math.floor((vim.o.lines - 20) / 2),
    col = math.floor((vim.o.columns - 80) / 2),
    border = 'rounded',
  })

  vim.keymap.set('n', '<CR>', function()
    M.run_tests(buf, challenge)
  end, { buffer = buf })

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
end

function M.run_tests(buf, challenge)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local code = table.concat(lines, '\n')

  local func, err = loadstring(code)
  if not func then
    vim.api.nvim_err_writeln('❌ Syntax Error: ' .. err)
    return
  end

  -- Run the user's code in a sandbox so `solution` doesn't leak into globals.
  local env = setmetatable({}, { __index = _G })
  setfenv(func, env)
  local status, exec_err = pcall(func)
  if not status then
    vim.api.nvim_err_writeln('❌ Execution Error: ' .. tostring(exec_err))
    return
  end

  local solution = env.solution
  if type(solution) ~= 'function' then
    vim.api.nvim_err_writeln("❌ Error: Function 'solution' is not defined!")
    return
  end

  local passed = 0
  for _, test in ipairs(challenge.tests) do
    local success, result = pcall(solution, test.input)
    if success and vim.deep_equal(result, test.expected) then
      passed = passed + 1
    end
  end

  if passed == #challenge.tests then
    local data = storage.load_data()
    local ui = require 'gamify.ui'

    if is_completed(data, challenge.id) then
      ui.show_popup('All tests passed! (already solved — no XP this time)', 'CHALLENGE COMPLETE', 'top_right')
      pcall(vim.api.nvim_win_close, 0, true)
      return
    end

    -- daily kata bonus: +50% XP, once per day
    local award = challenge.xp
    local today = os.date '%Y-%m-%d'
    if challenge.id == katas.daily_id() and data.daily_kata_done ~= today then
      award = math.floor(challenge.xp * 1.5)
      data.daily_kata_done = today
    end

    data.completed_katas = data.completed_katas or {}
    data.completed_katas[tostring(challenge.id)] = true
    storage.save_data(data)

    logic.add_xp(award)
    require('gamify.quests').on_kata()
    ui.show_popup('All tests passed! 🏆\nYou gained ' .. award .. ' XP', 'CHALLENGE COMPLETE', 'top_right')
    ui.show_falling_confetti(30, 2000)
    pcall(vim.api.nvim_win_close, 0, true)
  else
    vim.api.nvim_err_writeln(string.format('❌ Failed: %d/%d tests passed. Keep trying!', passed, #challenge.tests))
  end
end

return M
