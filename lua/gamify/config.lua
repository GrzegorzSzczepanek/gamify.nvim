local M = {}

M.defaults = {
  xp = {
    per_lines = 10,
    per_keypresses = 50,
    per_error_fixed = 5,
    clean_code = 15,
    new_day = 10,
    random_luck = 50,
    snake_per_apple = 10,
    saper_win = 200,
  },

  clean_code_once_per_buffer = true,
  random_luck_chance = 40,

  focus = {
    enabled = true,
    idle_timeout_sec = 120,
    tier_seconds = 300,
    max_multiplier = 3.0,
  },

  quests = {
    enabled = true,
    count = 3,
    completion_bonus = 200,
  },

  -- level = floor(1 + A * (xp ^ B))
  leveling = {
    A = 0.1,
    B = 0.5,
  },

  prestige = {
    enabled = true,
    level_required = 50,
    xp_bonus_per_rank = 0.05,
  },

  ui = {
    confetti = true,
    popups = true,
    xp_popups = true,
    popup_timeout_ms = 5000,
  },

  use_vim_notify = false,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts or {})
  return M.options
end

function M.get()
  return M.options
end

return M
