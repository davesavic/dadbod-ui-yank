local M = {}

local function get_dadbod_rows(range)
	local lines
	if range then
		lines = vim.api.nvim_buf_get_lines(0, range.start, range["end"], false)
	else
		local cursor = vim.api.nvim_win_get_cursor(0) -- {line, col}
		lines = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)
	end

	local rows = {}

	for _, line in ipairs(lines) do
		if not line:match("^%-%-+") and not line:match("%(%d+ rows?%)") and #vim.trim(line) > 0 then
			local row = vim.split(line, "|", { plain = true, trimempty = true })
			for i, col in ipairs(row) do
				row[i] = vim.trim(col)
			end
			table.insert(rows, row)
		end
	end

	return rows
end

local function to_json(rows)
	return vim.json.encode(rows)
end

local function to_csv(rows)
	local csv = {}
	for _, row in ipairs(rows) do
		table.insert(csv, table.concat(row, ","))
	end
	return table.concat(csv, "\n")
end

local function to_xml(rows)
	local xml = { "<rows>" }
	for _, row in ipairs(rows) do
		table.insert(xml, "  <row>")
		for _, col in ipairs(row) do
			table.insert(xml, "    <col>" .. vim.fn.escape(col, '&<>"') .. "</col>")
		end
		table.insert(xml, "  </row>")
	end
	table.insert(xml, "</rows>")
	return table.concat(xml, "\n")
end

function M.yank_as_format(format, range)
	local rows = get_dadbod_rows(range)
	if not rows or #rows == 0 then
		vim.notify("No valid rows found in the buffer.", vim.log.levels.WARN)
		return
	end

	local formatted_data
	if format == "json" then
		formatted_data = to_json(rows)
	elseif format == "csv" then
		formatted_data = to_csv(rows)
	elseif format == "xml" then
		formatted_data = to_xml(rows)
	else
		vim.notify("Unsupported format: " .. format, vim.log.levels.ERROR)
		return
	end

	vim.fn.setreg("+", formatted_data)
	vim.notify("Yanked rows as " .. format)
end

function M.setup()
	vim.api.nvim_create_user_command("DadbodYankAsJSON", function(opts)
		M.yank_as_format("json", opts.range ~= 0 and { start = opts.line1 - 1, ["end"] = opts.line2 } or nil)
	end, { range = true })

	vim.api.nvim_create_user_command("DadbodYankAsCSV", function(opts)
		M.yank_as_format("csv", opts.range ~= 0 and { start = opts.line1 - 1, ["end"] = opts.line2 } or nil)
	end, { range = true })

	vim.api.nvim_create_user_command("DadbodYankAsXML", function(opts)
		M.yank_as_format("xml", opts.range ~= 0 and { start = opts.line1 - 1, ["end"] = opts.line2 } or nil)
	end, { range = true })
end

return M
