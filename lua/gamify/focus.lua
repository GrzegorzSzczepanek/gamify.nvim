local M = {}

local config = require 'gamify.config'

local state = {
  session_start = nil,
  last_activity = nil,
}

local function now_ms()
  return vim.loop.now()
end

function M.tick()
  local cfg = config.get().focus
  if not cfg.enabled then
    return
  end

  local t = now_ms()
  if not state.last_activity or (t - state.last_activity) > cfg.idle_timeout_sec * 1000 then
    state.session_start = t
  end
  state.last_activity = t
end

function M.focused_seconds()
  local cfg = config.get().focus
  if not cfg.enabled or not state.session_start or not state.last_activity then
    return 0
  end
  if (now_ms() - state.last_activity) > cfg.idle_timeout_sec * 1000 then
    return 0
  end
  return (state.last_activity - state.session_start) / 1000
end

function M.current_multiplier()
  local cfg = config.get().focus
  if not cfg.enabled then
    return 1
  end
  local secs = M.focused_seconds()
  if secs <= 0 then
    return 1
  end
  local tiers = math.floor(secs / cfg.tier_seconds)
  return math.min(1 + tiers * 0.5, cfg.max_multiplier)
end

function M.status_text()
  local secs = M.focused_seconds()
  if secs <= 0 then
    return 'Focus: idle (x1.0)'
  end
  local mins = math.floor(secs / 60)
  return string.format('Focus: %dm streak (x%.1f)', mins, M.current_multiplier())
end

function M.flush()
  state.session_start = nil
  state.last_activity = nil
end

return M
