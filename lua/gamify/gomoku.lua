local M = {}

local SIZE = 20
local WIN_LEN = 5
local XP_WIN = 150

local CELL_EMPTY = '.'
local CELL_X = 'X'
local CELL_O = 'O'

local function new_board()
  local b = {}
  for y = 1, SIZE do
    b[y] = {}
    for x = 1, SIZE do
      b[y][x] = nil
    end
  end
  return b
end

-- Returns the list of winning cells {{x,y},...} if placing reaches WIN_LEN, else nil.
local function winning_line(board, x, y, player)
  local dirs = {
    { 1, 0 }, -- horizontal
    { 0, 1 }, -- vertical
    { 1, 1 }, -- diagonal ↘
    { 1, -1 }, -- diagonal ↗
  }
  for _, d in ipairs(dirs) do
    local dx, dy = d[1], d[2]
    local cells = { { x, y } }
    -- extend forward
    local cx, cy = x + dx, y + dy
    while board[cy] and board[cy][cx] == player do
      table.insert(cells, { cx, cy })
      cx, cy = cx + dx, cy + dy
    end
    -- extend backward
    cx, cy = x - dx, y - dy
    while board[cy] and board[cy][cx] == player do
      table.insert(cells, 1, { cx, cy })
      cx, cy = cx - dx, cy - dy
    end
    if #cells >= WIN_LEN then
      return cells
    end
  end
  return nil
end
M._winning_line = winning_line
M._new_board = new_board
M.SIZE = SIZE

-- session: holds all mutable game state and rendering for one window.
local function open_session(opts)
  opts = opts or {}
  local board = new_board()
  local cursor = { x = math.floor(SIZE / 2), y = math.floor(SIZE / 2) }
  local current = CELL_X
  local scores = { X = 0, O = 0 }
  local finished = false
  local win_cells = nil
  local status_msg = ''

  -- in LAN mode this client only controls `my_symbol`; nil = local hot-seat.
  local my_symbol = opts.my_symbol
  local on_move = opts.on_move -- function(x, y, player) called when *this* client places

  local buf = vim.api.nvim_create_buf(false, true)
  local board_w = SIZE * 2
  local width = math.max(board_w + 2, 40)
  local height = SIZE + 4
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = opts.title or ' ⬛ Gomoku (5-in-a-row) ',
    title_pos = 'center',
  })

  local ns = vim.api.nvim_create_namespace 'gamify_gomoku'

  local BOARD_BASE_ROW = 3 -- 0-based buffer line where the board grid starts
  local LEADING = 1 -- leading space before the first cell on each board line

  -- Buffer position (0-based row, 0-based byte col) of a logical cell.
  local function cell_pos(x, y)
    return BOARD_BASE_ROW + (y - 1), LEADING + (x - 1) * 2
  end

  local function in_win_cells(x, y)
    if not win_cells then
      return false
    end
    for _, c in ipairs(win_cells) do
      if c[1] == x and c[2] == y then
        return true
      end
    end
    return false
  end

  local function draw()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local lines = {}
    local turn_line
    if finished then
      turn_line = status_msg
    elseif my_symbol then
      turn_line = (current == my_symbol) and ('Your turn (' .. my_symbol .. ')') or ('Opponent (' .. current .. ')...')
    else
      turn_line = current .. "'s turn"
    end
    table.insert(lines, string.format('  X: %d   O: %d', scores.X, scores.O))
    table.insert(lines, '  ' .. turn_line)
    table.insert(lines, '')

    for y = 1, SIZE do
      local cells = {}
      for x = 1, SIZE do
        local v = board[y][x]
        table.insert(cells, v or CELL_EMPTY)
      end
      table.insert(lines, ' ' .. table.concat(cells, ' '))
    end
    table.insert(lines, '')

    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for y = 1, SIZE do
      for x = 1, SIZE do
        local v = board[y][x]
        local row, col = cell_pos(x, y)
        local hl
        if in_win_cells(x, y) then
          hl = 'GamifyGomokuWin'
        elseif v == CELL_X then
          hl = 'GamifyGomokuX'
        elseif v == CELL_O then
          hl = 'GamifyGomokuO'
        end
        if hl then
          vim.api.nvim_buf_add_highlight(buf, ns, hl, row, col, col + 1)
        end
      end
    end

    -- Highlight the focused cell and pin the real cursor onto it so the
    -- blinking cursor and the highlight always agree (never lands in a gap).
    if not finished then
      local row, col = cell_pos(cursor.x, cursor.y)
      vim.api.nvim_buf_add_highlight(buf, ns, 'GamifyGomokuCursor', row, col, col + 1)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_cursor(win, { row + 1, col })
      end
    end
  end

  local session = {
    buf = buf,
    win = win,
    board = board,
  }

  -- Place a stone. `external` = move came from the network (don't re-broadcast).
  local function place(x, y, player, external)
    if finished or board[y][x] ~= nil then
      return false
    end
    board[y][x] = player
    local line = winning_line(board, x, y, player)
    if line then
      finished = true
      win_cells = line
      scores[player] = scores[player] + 1
      status_msg = player .. ' wins! (q to close, r to rematch)'
      if not external then
        require('gamify.logic').add_xp(XP_WIN)
      end
      vim.schedule(function()
        local ui = require 'gamify.ui'
        ui.show_popup(player .. ' wins Gomoku!', 'Victory', 'top_right')
        ui.show_falling_confetti(30, 2000)
      end)
    else
      current = (player == CELL_X) and CELL_O or CELL_X
    end
    if not external and on_move then
      on_move(x, y, player)
    end
    draw()
    return true
  end
  session.place = place

  local function rematch()
    for y = 1, SIZE do
      for x = 1, SIZE do
        board[y][x] = nil
      end
    end
    finished = false
    win_cells = nil
    status_msg = ''
    current = CELL_X
    draw()
  end
  session.rematch = rematch

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if opts.on_close then
      opts.on_close()
    end
    require('gamify.ui').show_status_window(require('gamify.achievements').get_achievements_table_length())
  end
  session.close = close

  local function try_place_here()
    if finished then
      return
    end
    if my_symbol and current ~= my_symbol then
      return -- not your turn in LAN mode
    end
    place(cursor.x, cursor.y, current, false)
  end

  local function move_cursor(dx, dy)
    cursor.x = math.max(1, math.min(SIZE, cursor.x + dx))
    cursor.y = math.max(1, math.min(SIZE, cursor.y + dy))
    draw()
  end

  vim.keymap.set('n', 'h', function() move_cursor(-1, 0) end, { buffer = buf })
  vim.keymap.set('n', 'l', function() move_cursor(1, 0) end, { buffer = buf })
  vim.keymap.set('n', 'k', function() move_cursor(0, -1) end, { buffer = buf })
  vim.keymap.set('n', 'j', function() move_cursor(0, 1) end, { buffer = buf })
  vim.keymap.set('n', '<Left>', function() move_cursor(-1, 0) end, { buffer = buf })
  vim.keymap.set('n', '<Right>', function() move_cursor(1, 0) end, { buffer = buf })
  vim.keymap.set('n', '<Up>', function() move_cursor(0, -1) end, { buffer = buf })
  vim.keymap.set('n', '<Down>', function() move_cursor(0, 1) end, { buffer = buf })
  vim.keymap.set('n', '<CR>', try_place_here, { buffer = buf })
  vim.keymap.set('n', '<Space>', try_place_here, { buffer = buf })

  -- Safety net: if any unmapped motion drifts the real cursor, snap it back
  -- to the focused cell so it can never sit in the gaps between stones.
  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = buf,
    callback = function()
      if finished or not vim.api.nvim_win_is_valid(win) then
        return
      end
      local row, col = cell_pos(cursor.x, cursor.y)
      local cur = vim.api.nvim_win_get_cursor(win)
      if cur[1] ~= row + 1 or cur[2] ~= col then
        vim.api.nvim_win_set_cursor(win, { row + 1, col })
      end
    end,
  })
  vim.keymap.set('n', 'r', function()
    if my_symbol then
      return -- rematch sync not supported in LAN yet
    end
    rematch()
  end, { buffer = buf })
  vim.keymap.set('n', 'q', close, { buffer = buf })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf })

  vim.cmd [[
    highlight default GamifyGomokuX      gui=bold guifg=#F38BA8
    highlight default GamifyGomokuO      gui=bold guifg=#89B4FA
    highlight default GamifyGomokuWin    gui=bold guifg=#000000 guibg=#A6E3A1
    highlight default GamifyGomokuCursor gui=bold guifg=#1E1E2E guibg=#F9E2AF
  ]]

  draw()
  return session
end
M._open_session = open_session

function M.start_local()
  require('gamify.quests').on_game()
  open_session { title = ' ⬛ Gomoku — Local (h,j,k,l, <CR>) ' }
end

----------------------------------------------------------------------
-- LAN mode (vim.loop TCP). Protocol: newline-delimited messages.
--   "SYM X"        server → client: assigned symbol
--   "MOVE x,y,P"   either direction: a placed stone
--   "RST"          rematch
----------------------------------------------------------------------

-- Parse and feed inbound newline-delimited messages into the session.
local function make_reader(on_message)
  local acc = ''
  return function(chunk)
    acc = acc .. chunk
    while true do
      local nl = acc:find '\n'
      if not nl then
        break
      end
      local line = acc:sub(1, nl - 1)
      acc = acc:sub(nl + 1)
      if line ~= '' then
        on_message(line)
      end
    end
  end
end

function M.host(port)
  port = tonumber(port) or 5050
  require('gamify.quests').on_game()
  local server = vim.loop.new_tcp()
  local ok, err = pcall(function()
    server:bind('0.0.0.0', port)
  end)
  if not ok then
    vim.notify('Gomoku host failed to bind port ' .. port .. ': ' .. tostring(err), vim.log.levels.ERROR, { title = 'Gamify' })
    return
  end

  vim.notify('Gomoku: waiting for opponent on port ' .. port .. '…', vim.log.levels.INFO, { title = 'Gamify' })

  local client_sock
  local session

  local function send(msg)
    if client_sock and not client_sock:is_closing() then
      client_sock:write(msg .. '\n')
    end
  end

  server:listen(1, function(listen_err)
    if listen_err then
      return
    end
    local sock = vim.loop.new_tcp()
    server:accept(sock)
    client_sock = sock
    -- host is X
    sock:write('SYM O\n') -- tell client they are O
    vim.schedule(function()
      session = open_session {
        title = ' ⬛ Gomoku — LAN host (X) ',
        my_symbol = 'X',
        on_move = function(x, y, p)
          send(string.format('MOVE %d,%d,%s', x, y, p))
        end,
        on_close = function()
          if sock and not sock:is_closing() then sock:close() end
          if not server:is_closing() then server:close() end
        end,
      }
      local feed = make_reader(function(line)
        local x, y, p = line:match '^MOVE (%d+),(%d+),(%a)'
        if x then
          vim.schedule(function()
            session.place(tonumber(x), tonumber(y), p, true)
          end)
        end
      end)
      sock:read_start(function(rerr, chunk)
        if rerr or not chunk then
          return
        end
        feed(chunk)
      end)
    end)
  end)
end

function M.join(host, port)
  port = tonumber(port) or 5050
  if not host or host == '' then
    vim.notify('Usage: :Gomoku join <host> [port]', vim.log.levels.ERROR, { title = 'Gamify' })
    return
  end
  require('gamify.quests').on_game()
  local sock = vim.loop.new_tcp()
  sock:connect(host, port, function(err)
    if err then
      vim.schedule(function()
        vim.notify('Gomoku: could not connect to ' .. host .. ':' .. port .. ' (' .. tostring(err) .. ')', vim.log.levels.ERROR, { title = 'Gamify' })
      end)
      return
    end

    local session
    local function send(msg)
      if not sock:is_closing() then
        sock:write(msg .. '\n')
      end
    end

    local feed = make_reader(function(line)
      local sym = line:match '^SYM (%a)'
      if sym then
        vim.schedule(function()
          session = open_session {
            title = ' ⬛ Gomoku — LAN join (' .. sym .. ') ',
            my_symbol = sym,
            on_move = function(x, y, p)
              send(string.format('MOVE %d,%d,%s', x, y, p))
            end,
            on_close = function()
              if not sock:is_closing() then sock:close() end
            end,
          }
        end)
        return
      end
      local x, y, p = line:match '^MOVE (%d+),(%d+),(%a)'
      if x then
        vim.schedule(function()
          if session then
            session.place(tonumber(x), tonumber(y), p, true)
          end
        end)
      end
    end)

    sock:read_start(function(rerr, chunk)
      if rerr or not chunk then
        return
      end
      feed(chunk)
    end)
  end)
end

return M
