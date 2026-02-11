local M = {}
-- define signs
vim.api.nvim_command("sign define diffadd text=+ texthl=DiffAdd")
vim.api.nvim_command("sign define diffdelete text=󰾞 texthl=DiffDelete")

M.config = {
	keymaps = {
		goto_hunk_next = "",
		goto_hunk_prev = "",
	},
}

local get_type = function(line)
	if vim.startswith(line, "+") then
		return "diffadd"
	else
		return "diffdelete"
	end
end

local sign_line = function(line_number, line)
	local line_nr = tonumber(line_number)
	if line_nr == 0 then
		line_nr = 1
	end
	vim.api.nvim_command("sign place " .. line_nr .. " line=" .. line_nr .. " name=" .. get_type(line))
end

local is_real_file_buffer = function(buf)
	local bo = vim.bo[buf]

	-- 1. Must be a normal file buffer
	if bo.buftype ~= "" then
		return false
	end

	-- 2. Must have a name (rules out [No Name], plugin buffers, etc)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		return false
	end

	-- 3. Must not be a directory
	if vim.fn.isdirectory(name) == 1 then
		return false
	end

	return true
end

local is_git_working_file = function(buf)
	if not is_real_file_buffer(buf) then
		return false
	end

	local name = vim.api.nvim_buf_get_name(buf)
	local dir = vim.fn.fnamemodify(name, ":h")

	-- find git root upward from the file's directory
	local git_root = vim.fn.finddir(".git", dir .. ";")
	if git_root == "" then
		return false
	end

	return true
end

local hunk_line_number = function(diff, hunk_number)
	local cline_nlines_pair = string.sub(vim.split(diff[hunk_number], " ")[3], 2)
	return tonumber(vim.split(cline_nlines_pair, ",")[1])
end

function M.goto_hunk(move)
	local path = vim.fn.expand("%:p")
	local diff = vim.fn.systemlist("git diff --unified=0 " .. path .. " | grep '^@@'")
	local cursor_line = vim.fn.line(".")

	if #diff == 0 then
		vim.notify("No valid changes to move to", vim.log.levels.ERROR)
		return
	end

	for i, _ in ipairs(diff) do
		-- iterate over changed hunks
		local line_number = hunk_line_number(diff, i)

		if move == "next" then
			if line_number > cursor_line then
				vim.api.nvim_command("normal! " .. line_number .. "G")
				break
			elseif i == #diff then
				line_number = hunk_line_number(diff, 1)
				vim.api.nvim_command("normal! " .. line_number .. "G")
				break
			end
		end
		if move == "prev" then
			if line_number < cursor_line then
				vim.api.nvim_command("normal! " .. line_number .. "G")
			elseif i == 1 then
				line_number = hunk_line_number(diff, #diff)
				vim.api.nvim_command("normal! " .. line_number .. "G")
			end
		end
	end
end

function M.set_diff_signs()
	local path = vim.fn.expand("%:p")
	local diff = vim.fn.systemlist("git diff --unified=0 " .. path)
	-- sign unplace on current buffer
	vim.api.nvim_command("sign unplace * file=" .. path .. "")

	-- iterate over changed hunks
	for index, line in ipairs(diff) do
		if vim.startswith(line, "@@") then
			local cline_nlines_pair = string.sub(vim.split(line, " ")[3], 2)
			local line_number = vim.split(cline_nlines_pair, ",")[1]
			local nr_of_lines = vim.split(cline_nlines_pair, ",")[2]

			-- check change is one line only
			if nr_of_lines == nil or nr_of_lines == "0" then
				sign_line(line_number, diff[index + 1])
			else
				-- sign when multiple lines are changed
				for i = 1, nr_of_lines do
					sign_line(line_number + i - 1, diff[index + 1])
				end
			end
		end
	end
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	local group_git = vim.api.nvim_create_augroup("CustomGit", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
		callback = function(args)
			if is_git_working_file(args.buf) then
				M.set_diff_signs()
			end
		end,
		group = group_git,
	})

	vim.api.nvim_create_user_command("GitHunkNext", function()
		M.goto_hunk("next")
	end, {})
	vim.api.nvim_create_user_command("GitHunkPrev", function()
		M.goto_hunk("prev")
	end, {})

	if M.config.keymaps.goto_hunk_next ~= "" then
		vim.api.nvim_set_keymap("n", M.config.keymaps.goto_hunk_next, ":GitHunkNext<CR>", {})
	end
	if M.config.keymaps.goto_hunk_prev ~= "" then
		vim.api.nvim_set_keymap("n", M.config.keymaps.goto_hunk_prev, ":GitHunkPrev<CR>", {})
	end
end

return M
