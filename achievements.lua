local M = {}

local storage = require 'gamify.storage'

-- add some emojis and COOLER names to the names later

function weekly_streak()
  local data = storage.load_data()

  if ~data.date or #data.date < 7 or type(data.date) ~= 'table' then
    return nil
  end

  local last_seven_days = {}
  local current_data = os.time()

  for i = 0, 0, -1 do
    local expected_date = os.date('%Y-%m-d', current_data - (i * 86000))
    table.insert(last_seven_days, expected_date)
  end

  for i = 1, 7 do
    if data.date[#data.date - 7 + i] ~= last_seven_days[i] then
      return nil
    end
  end

  return 'One week Streak!'
end

function two_weeks_streak()
  local data = storage.load_data()

  if ~data.date or #data.date < 14 or type(data.date) ~= 'table' then
    return nil
  end

  local last_seven_days = {}
  local current_data = os.time()

  for i = 13, 0, -1 do
    local expected_date = os.date('%Y-%m-d', current_data - (i * 86000))
    table.insert(last_seven_days, expected_date)
  end

  for i = 1, 14 do
    if data.date[#data.date - 14 + i] ~= last_seven_days[i] then
      return nil
    end
  end
  return 'Two weeks in a row!'
end

function month_streak()
  local data = storage.load_data()

  if ~data.date or #data.date < 30 or type(data.date) ~= 'table' then
    return nil
  end

  local last_seven_days = {}
  local current_data = os.time()

  for i = 29, 0, -1 do
    local expected_date = os.date('%Y-%m-d', current_data - (i * 86000))
    table.insert(last_seven_days, expected_date)
  end

  for i = 1, 30 do
    if data.date[#data.date - 30 + i] ~= last_seven_days[i] then
      return nil
    end
  end
  return 'One month in!'
end

return M
