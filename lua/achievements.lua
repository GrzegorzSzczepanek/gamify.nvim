local M = {}

local storage = require("gamify.storage")
local logic = require("gamify.logic")
local utils = require("gamify.utils")
local ui = require("gamify.ui")

local function check_lines(lines_needed)
	local data = storage.load_data()
	return (data.lines_written or 0) >= lines_needed
end

local function lines_in_languages(num_of_langs, threshold)
	local data = storage.load_data()
	local lines_per_lang = data.lines_written_in_specified_langs or {}
	local count_above_threshold = 0

	for _, lines in pairs(lines_per_lang) do
		if lines >= threshold then
			count_above_threshold = count_above_threshold + 1
		end
	end

	return count_above_threshold == num_of_langs
end

local achievement_definitions = {
	{
		name = "Weekly Streak",
		description = "Open Neovim every day for 7 consecutive days",
		xp = 500,
		check = function()
			return storage.load_data().day_streak >= 7
		end,
	},
	{
		name = "Two Weeks Streak",
		description = "Open Neovim every day for 14 consecutive days",
		xp = 1500,
		check = function()
			return storage.load_data().day_streak >= 14
		end,
	},
	{
		name = "One Month Streak",
		description = "Open Neovim every day for 30 consecutive days",
		xp = 4000,
		check = function()
			return storage.load_data().day_streak >= 30
		end,
	},

	{
		name = "Hundred lines",
		description = "Write 100 lines of code",
		xp = 100,
		check = function()
			return check_lines(100)
		end,
	},
	{
		name = "Thousand Lines",
		description = "Write 1000 lines of code",
		xp = 150,
		check = function()
			return check_lines(1000)
		end,
	},
	{
		name = "Two Thousand Lines",
		description = "Write 2000 lines of code",
		xp = 350,
		check = function()
			return check_lines(2000)
		end,
	},
	{
		name = "Five Thousand Lines",
		description = "Write 5000 lines of code",
		xp = 600,
		check = function()
			return check_lines(5000)
		end,
	},
	{
		name = "Ten Thousand Lines",
		description = "Write 10000 lines of code",
		xp = 800,
		check = function()
			return check_lines(10000)
		end,
	},
	{
		name = "Twenty Five Thousand Lines",
		description = "Write 25000 lines of code",
		xp = 2000,
		check = function()
			return check_lines(25000)
		end,
	},

	{
		name = "Night Owl",
		description = "Code for at least 3 hours between 11PM and 4AM five times",
		xp = 1000,
		check = function()
			local data = storage.load_data()
			return (data.code_nights or 0) == 4
		end,
	},

	{
		name = "Early Bird",
		description = "Code for at least 3 hours between 6AM and 11AM five times",
		xp = 1000,
		check = function()
			local data = storage.load_data()
			return (data.code_mornings or 0) == 4
		end,
	},

	{
		name = "Jack of Many",
		description = "Write at least 1000 lines in at least 5 languages",
		xp = 2500,
		check = function()
			return lines_in_languages(5, 1000)
		end,
	},
	{
		name = "Polyglot",
		description = "Write at least 1000 lines in at least 10 languages",
		xp = 5000,
		check = function()
			return lines_in_languages(10, 1000)
		end,
	},

	{
		name = "Marathoner",
		description = "Code continuously for at least 6 hours",
		xp = 1800,
		check = function()
			return utils.calculate_time_difference() >= 6
		end,
	},

	{
		name = "Git Apprentice",
		description = "Make 10 total commits in your coding journey",
		xp = 300,
		check = function()
			local data = storage.load_data()
			return #data.commit_hashes >= 10
		end,
	},
	{
		name = "Git Journeyman",
		description = "Make 50 total commits in your coding journey",
		xp = 1000,
		check = function()
			local data = storage.load_data()
			return #data.commit_hashes >= 50
		end,
	},
	{
		name = "Git Master",
		description = "Make 100 total commits in your coding journey",
		xp = 3000,
		check = function()
			local data = storage.load_data()
			return #data.commit_hashes >= 100
		end,
	},
	{
		name = "Commit Deity",
		description = "Make 500 total commits in your coding journey",
		xp = 8000,
		check = function()
			local data = storage.load_data()
			return #data.commit_hashes >= 500
		end,
	},
	{
		name = "Vim enjoyer",
		description = "Spend at least 100 hours in nvim",
		xp = 4500,
		check = function()
			return storage.load_data().total_time >= 100.0
		end,
	},
	{
		name = "Get a Life!",
		description = "Spend at least 200 hours in nvim",
		xp = 9000,
		check = function()
			return storage.load_data().total_time >= 200.0
		end,
	},
}

function M.get_achievements_table_length()
	return utils.get_table_length(achievement_definitions)
end

function M.check_all_achievements()
	local data = storage.load_data()
	local delay = 0

	for _, achievement in ipairs(achievement_definitions) do
		local already_unlocked = data.achievements[achievement.name] ~= nil
		local meets_requirement = achievement.check()

		if meets_requirement and not already_unlocked then
			logic.add_xp(achievement.xp, achievement)

			vim.defer_fn(function()
				ui.show_special_popup(achievement.name)
			end, delay)

			delay = delay + 3000
		end
	end
end

function M.track_error_fixes()
	local previous_error_count = 0

	local diagnostics = vim.diagnostic.get(0)
	local current_error_count = 0

	for _, diag in ipairs(diagnostics) do
		if diag.severity == vim.diagnostic.severity.ERROR then
			current_error_count = current_error_count + 1
		end
	end

	if current_error_count < previous_error_count then
		local resolved_errors = previous_error_count - current_error_count
		local data = storage.load_data()
		data.errors_fixed = (data.errors_fixed or 0) + resolved_errors
		storage.save_data(data)
	end

	previous_error_count = current_error_count
end

return M
