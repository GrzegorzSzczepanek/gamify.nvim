local M = {}
local logic = require 'gamify.logic'
local ui = require 'gamify.ui'

function M.start_snake()
  require('gamify.quests').on_game()
  local width = 60
  local height = 25
  local buf = vim.api.nvim_create_buf(false, true)
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' 🐍 Vim Snake (h,j,k,l) ',
    title_pos = 'center',
  }
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Game state
  local snake = { { x = 10, y = 10 }, { x = 10, y = 11 }, { x = 10, y = 12 } }
  local direction = { x = 0, y = -1 } -- Start moving up
  local food = { x = math.random(width), y = math.random(height) }
  local score = 0
  local game_over = false

  local function draw()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local lines = {}
    for y = 1, height do
      local line = ''
      for x = 1, width do
        local is_snake = false
        for i, part in ipairs(snake) do
          if part.x == x and part.y == y then
            line = line .. (i == 1 and 'O' or 'o')
            is_snake = true
            break
          end
        end
        if not is_snake then
          if food.x == x and food.y == y then
            line = line .. '🍎'
          else
            line = line .. ' '
          end
        end
      end
      table.insert(lines, line)
    end
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end

  local timer = vim.loop.new_timer()
  local function update()
    if game_over then
      timer:stop()
      timer:close()
      return
    end

    local head = { x = snake[1].x + direction.x, y = snake[1].y + direction.y }

    -- Collisions
    if head.x < 1 or head.x > width or head.y < 1 or head.y > height then
      game_over = true
    end
    for _, part in ipairs(snake) do
      if head.x == part.x and head.y == part.y then
        game_over = true
      end
    end

    if not game_over then
      table.insert(snake, 1, head)
      if head.x == food.x and head.y == food.y then
        score = score + 1
        food = { x = math.random(width), y = math.random(height) }
      else
        table.remove(snake)
      end
      draw()
    else
      local xp_reward = score * 10
      logic.add_xp(xp_reward)
      
      -- Update high score
      local storage = require('gamify.storage')
      local data = storage.load_data()
      if score > (data.high_scores.snake or 0) then
        data.high_scores.snake = score
        storage.save_data(data)
        vim.schedule(function()
          require('gamify.ui').show_popup("New High Score: " .. score .. "! 🏆", "Snake Record", "top_right")
        end)
      end

      vim.schedule(function()
        vim.api.nvim_err_writeln('Game Over! Score: ' .. score .. ' | XP Gained: ' .. xp_reward)
        -- Give a moment to see the score before returning
        vim.defer_fn(function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
          require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
        end, 2000)
      end)
    end
  end

  -- Keybindings
  local function set_dir(x, y)
    -- Prevent 180 degree turns
    if (x ~= 0 and direction.x == 0) or (y ~= 0 and direction.y == 0) then
      direction = { x = x, y = y }
    end
  end

  vim.keymap.set('n', 'h', function() set_dir(-1, 0) end, { buffer = buf })
  vim.keymap.set('n', 'l', function() set_dir(1, 0) end, { buffer = buf })
  vim.keymap.set('n', 'k', function() set_dir(0, -1) end, { buffer = buf })
  vim.keymap.set('n', 'j', function() set_dir(0, 1) end, { buffer = buf })
  vim.keymap.set('n', '<Esc>', function()
    game_over = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buf })
  vim.keymap.set('n', 'q', function()
    game_over = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buf })

  timer:start(0, 150, vim.schedule_wrap(update))
end

function M.start_minesweeper()
  require('gamify.quests').on_game()
  local width = 10
  local height = 10
  local mine_count = 15
  local buf = vim.api.nvim_create_buf(false, true)
  local win_opts = {
    relative = 'editor',
    width = width * 5 + 4,
    height = height * 2 + 2,
    row = math.floor((vim.o.lines - (height * 2 + 2)) / 2),
    col = math.floor((vim.o.columns - (width * 5 + 4)) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' 💣 Saper (h,j,k,l, <CR>:Reveal, f:Flag) ',
    title_pos = 'center',
  }
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Game state
  local board = {}
  local revealed = {}
  local flags = {}
  local cursor = { x = 1, y = 1 }
  local game_over = false
  local first_click = true
  local start_time = nil

  local function init_board(safe_x, safe_y)
    start_time = os.time()
    board = {}
    for y = 1, height do
      board[y] = {}
      for x = 1, width do board[y][x] = 0 end
    end

    local placed = 0
    while placed < mine_count do
      local rx, ry = math.random(width), math.random(height)
      if board[ry][rx] ~= -1 and (rx ~= safe_x or ry ~= safe_y) then
        board[ry][rx] = -1
        placed = placed + 1
      end
    end

    for y = 1, height do
      for x = 1, width do
        if board[y][x] ~= -1 then
          local count = 0
          for dy = -1, 1 do
            for dx = -1, 1 do
              local ny, nx = y + dy, x + dx
              if board[ny] and board[ny][nx] == -1 then count = count + 1 end
            end
          end
          board[y][x] = count
        end
      end
    end
  end

  local function draw()
    local lines = { "" }
    for y = 1, height do
      local line = '  '
      for x = 1, width do
        local char = '■ '
        if revealed[y] and revealed[y][x] then
          if board[y][x] == -1 then char = '💣'
          elseif board[y][x] == 0 then char = '· '
          else char = board[y][x] .. ' ' end
        elseif flags[y] and flags[y][x] then
          char = '🚩'
        end
        
        if cursor.x == x and cursor.y == y then
          char = '[' .. char:sub(1, 2):gsub("%s+", "") .. ']'
          if #char == 3 then char = char .. " " end
        else
          char = ' ' .. char .. ' '
        end
        line = line .. char
      end
      table.insert(lines, line)
      table.insert(lines, "")
    end
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end

  local function reveal(x, y)
    if x < 1 or x > width or y < 1 or y > height or (revealed[y] and revealed[y][x]) or (flags[y] and flags[y][x]) then return end
    revealed[y] = revealed[y] or {}
    revealed[y][x] = true

    if board[y][x] == -1 then
      game_over = true
      return
    end

    if board[y][x] == 0 then
      for dy = -1, 1 do
        for dx = -1, 1 do reveal(x + dx, y + dy) end
      end
    end
  end

  local function check_win()
    local revealed_count = 0
    for y = 1, height do
      for x = 1, width do
        if revealed[y] and revealed[y][x] then revealed_count = revealed_count + 1 end
      end
    end
    if revealed_count == (width * height - mine_count) then
      local time_taken = os.difftime(os.time(), start_time)
      logic.add_xp(200)

      -- Update best time
      local storage = require('gamify.storage')
      local data = storage.load_data()
      if not data.high_scores.saper or time_taken < data.high_scores.saper then
        data.high_scores.saper = time_taken
        storage.save_data(data)
        vim.schedule(function()
          require('gamify.ui').show_popup("New Best Time: " .. time_taken .. "s! 🏆", "Saper Record", "top_right")
        end)
      end

      require('gamify.ui').show_popup("You Won Saper! +200 XP 🏆", "Victory", "top_right")
      require('gamify.ui').show_falling_confetti(30, 2000)
      vim.api.nvim_win_close(win, true)
      require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
    end
  end

  local function handle_reveal()
    if game_over then return end
    if first_click then
      init_board(cursor.x, cursor.y)
      first_click = false
    end
    reveal(cursor.x, cursor.y)
    if game_over then
      vim.api.nvim_err_writeln("BOOM! Game Over.")
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
        require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
      end, 2000)
    else
      check_win()
    end
    draw()
  end

  local function toggle_flag()
    if revealed[cursor.y] and revealed[cursor.y][cursor.x] then return end
    flags[cursor.y] = flags[cursor.y] or {}
    flags[cursor.y][cursor.x] = not flags[cursor.y][cursor.x]
    draw()
  end

  vim.keymap.set('n', 'h', function() cursor.x = math.max(1, cursor.x - 1); draw() end, { buffer = buf })
  vim.keymap.set('n', 'l', function() cursor.x = math.min(width, cursor.x + 1); draw() end, { buffer = buf })
  vim.keymap.set('n', 'k', function() cursor.y = math.max(1, cursor.y - 1); draw() end, { buffer = buf })
  vim.keymap.set('n', 'j', function() cursor.y = math.min(height, cursor.y + 1); draw() end, { buffer = buf })
  vim.keymap.set('n', '<CR>', handle_reveal, { buffer = buf })
  vim.keymap.set('n', 'f', toggle_flag, { buffer = buf })
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buf })
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buf })

  draw()
end

function M.start_sudoku()
  require('gamify.quests').on_game()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 55
  local height = 25
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' 🧩 Sudoku (h,j,k,l, 1-9:Enter, 0/x:Clear) ',
    title_pos = 'center',
  }
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  local grid = {}
  local initial = {}
  local cursor = { x = 0, y = 0 }
  local difficulty = "Medium"
  local start_time = os.time()

  local function is_valid(g, r, c, val)
    for i = 0, 8 do
      if g[r][i] == val or g[i][c] == val then return false end
    end
    local br, bc = math.floor(r / 3) * 3, math.floor(c / 3) * 3
    for i = 0, 2 do
      for j = 0, 2 do
        if g[br + i][bc + j] == val then return false end
      end
    end
    return true
  end

  local function solve(g)
    for r = 0, 8 do
      for c = 0, 8 do
        if g[r][c] == 0 then
          local nums = {1,2,3,4,5,6,7,8,9}
          for i = #nums, 2, -1 do
            local j = math.random(i)
            nums[i], nums[j] = nums[j], nums[i]
          end
          for _, val in ipairs(nums) do
            if is_valid(g, r, c, val) then
              g[r][c] = val
              if solve(g) then return true end
              g[r][c] = 0
            end
          end
          return false
        end
      end
    end
    return true
  end

  local function generate()
    grid = {}
    for i = 0, 8 do grid[i] = {}; for j = 0, 8 do grid[i][j] = 0 end end
    solve(grid)
    local clues = difficulty == "Easy" and 45 or (difficulty == "Hard" and 25 or 35)
    local removed = 0
    while removed < (81 - clues) do
      local r, c = math.random(0, 8), math.random(0, 8)
      if grid[r][c] ~= 0 then
        grid[r][c] = 0
        removed = removed + 1
      end
    end
    initial = {}
    for r = 0, 8 do
      initial[r] = {}
      for c = 0, 8 do initial[r][c] = grid[r][c] ~= 0 end
    end
  end

  local function draw()
    local lines = { "", ui.center_text("Difficulty: " .. difficulty .. " (Press d to change)", width), "" }
    for r = 0, 8 do
      local line = "      "
      if r > 0 and r % 3 == 0 then 
        table.insert(lines, "      " .. string.rep("—", 37))
        table.insert(lines, "")
      end
      for c = 0, 8 do
        if c > 0 and c % 3 == 0 then line = line .. "| " end
        local val = grid[r][c] == 0 and "." or tostring(grid[r][c])
        if cursor.x == c and cursor.y == r then
          line = line .. "[" .. val .. "] "
        else
          line = line .. " " .. val .. "  "
        end
      end
      table.insert(lines, line)
      table.insert(lines, "")
    end
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end

  local function check_win()
    for r = 0, 8 do
      for c = 0, 8 do
        if grid[r][c] == 0 then return end
        local v = grid[r][c]
        grid[r][c] = 0
        if not is_valid(grid, r, c, v) then
          grid[r][c] = v
          return
        end
        grid[r][c] = v
      end
    end
    local time_taken = os.difftime(os.time(), start_time)
    local xp = difficulty == "Easy" and 100 or (difficulty == "Hard" and 500 or 250)
    logic.add_xp(xp)

    -- Update best time
    local storage = require('gamify.storage')
    local data = storage.load_data()
    if not data.high_scores.sudoku or time_taken < data.high_scores.sudoku then
      data.high_scores.sudoku = time_taken
      storage.save_data(data)
      vim.schedule(function()
        require('gamify.ui').show_popup("New Best Time: " .. time_taken .. "s! 🏆", "Sudoku Record", "top_right")
      end)
    end

    require('gamify.ui').show_popup("Sudoku Solved! +" .. xp .. " XP 🏆", "Victory", "top_right")
    require('gamify.ui').show_falling_confetti(30, 2000)
    vim.api.nvim_win_close(win, true)
    require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
  end

  generate()

  vim.keymap.set('n', 'h', function() cursor.x = (cursor.x - 1 + 9) % 9; draw() end, { buffer = buf })
  vim.keymap.set('n', 'l', function() cursor.x = (cursor.x + 1) % 9; draw() end, { buffer = buf })
  vim.keymap.set('n', 'k', function() cursor.y = (cursor.y - 1 + 9) % 9; draw() end, { buffer = buf })
  vim.keymap.set('n', 'j', function() cursor.y = (cursor.y + 1) % 9; draw() end, { buffer = buf })
  vim.keymap.set('n', 'd', function()
    if difficulty == "Easy" then difficulty = "Medium"
    elseif difficulty == "Medium" then difficulty = "Hard"
    else difficulty = "Easy" end
    generate(); draw()
  end, { buffer = buf })

  for i = 1, 9 do
    vim.keymap.set('n', tostring(i), function()
      if not initial[cursor.y][cursor.x] then
        grid[cursor.y][cursor.x] = i
        draw(); check_win()
      end
    end, { buffer = buf })
  end
  vim.keymap.set('n', '0', function() if not initial[cursor.y][cursor.x] then grid[cursor.y][cursor.x] = 0; draw() end end, { buffer = buf })
  vim.keymap.set('n', 'x', function() if not initial[cursor.y][cursor.x] then grid[cursor.y][cursor.x] = 0; draw() end end, { buffer = buf })

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buf })
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
  end, { buffer = buf })

  draw()
end

return M
