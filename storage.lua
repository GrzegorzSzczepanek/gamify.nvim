local M = {}

local data_file = vim.fn.stdpath("data") .. "/gamify/data.json"
M.last_entry_format = os.date("%Y-%m-%d %H:%M:%S")
M.date_format = os.date("%Y-%m-%d")
M.data_json_format = {
	xp = 0,
	achievements = {},
	goals = {},
	date = {},
	lines_written = 0,
	last_entry = M.last_entry_format,
	total_time = 0,
	level = 0,
	time_spent = 0,
	code_nights = 0,
	code_mornings = 0,
	lines_written_in_specified_langs = {},
	errors_fixed = 0,
	day_streak = 1,
	commit_hashes = {},
}

function M.load_data()
	local file = io.open(data_file, "r")
	if not file then
		return M.data_json_format
	end

	local content = file:read("*a")
	file:close()

	local data = vim.fn.json_decode(content)

	local defaults = M.data_json_format
	for k, v in pairs(defaults) do
		if data[k] == nil then
			data[k] = v
		end
	end

	return data
end

function M.save_data(data)
	local file = io.open(data_file, "w")
	if not file then
		error("Failed to open file for writing: " .. data_file)
	end
	file:write(vim.fn.json_encode(data))
	file:close()
end

function M.get_last_day()
	local data = M.load_data()

	if data.date and type(data.date) == "table" and #data.date > 0 then
		return data.date[#data.date]
	end

	return nil
end

function M.validate_time_entry(entry)
	if type(entry) == "string" and entry:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$") then
		return true
	end
	return false
end

function M.get_last_log()
	local data = M.load_data()
	local entry = data.last_entry or os.date("%Y-%m-%d %H:%M:%S")

	if entry and M.validate_time_entry(entry) then
		return entry
	end
	return os.date("%Y-%m-%d %H:%M:%S")
end

-- it returns boolean so we can know if we should add exp to user for logging
function M.log_new_day()
	local current_date = M.date_format
	local last_day_entry = M.get_last_day()

	-- Extract date part from last_entry if present
	local last_logged_date = last_day_entry and last_day_entry:match("%d%d%d%d%-%d%d%-%d%d") or nil

	-- Compare only the date part
	if last_logged_date ~= current_date then
		local data = M.load_data()
		data.date = data.date or {}
		table.insert(data.date, M.date_format)
		M.save_data(data)
		return true
	end

	return false
end

return M
