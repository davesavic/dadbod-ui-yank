local M = {}

local function get_headers(lines)
	for i, line in ipairs(lines) do
		if line:match("^%-%-+") then
			local headers = vim.split(lines[i - 1] or "", "|", { plain = true, trimempty = true })
			for j, header in ipairs(headers) do
				headers[j] = vim.trim(header)
			end
			return headers
		end
	end
	return {}
end

local function get_dadbod_rows(range, with_headers)
	local lines
	if range then
		lines = vim.api.nvim_buf_get_lines(0, range.start, range["end"], false)
	else
		local cursor = vim.api.nvim_win_get_cursor(0)
		lines = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)
	end

	local full_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local global_headers = get_headers(full_lines)

	local headers = nil
	local rows = {}
	local data_start = false
	local selection_contains_headers = false

	for i, line in ipairs(lines) do
		if line:match("^%-%-+") then
			data_start = true
			if i > 1 and with_headers then
				headers = vim.split(lines[i - 1], "|", { plain = true, trimempty = true })
				for j, col in ipairs(headers) do
					headers[j] = vim.trim(col)
				end
				selection_contains_headers = true
			end
		elseif data_start and #vim.trim(line) > 0 and not line:match("%(%d+ rows?%)") then
			local row = vim.split(line, "|", { plain = true, trimempty = true })
			for j, col in ipairs(row) do
				row[j] = vim.trim(col)
			end
			table.insert(rows, row)
		end
	end

	if with_headers then
		if not selection_contains_headers then
			headers = global_headers
		end
	else
		headers = nil
	end

	return headers, rows
end

local function to_json(headers, rows)
	if headers and #headers > 0 then
		local json_rows = {}
		for _, row in ipairs(rows) do
			local json_object = {}
			for i, value in ipairs(row) do
				json_object[headers[i]] = value
			end
			table.insert(json_rows, json_object)
		end
		return vim.json.encode(json_rows)
	else
		return vim.json.encode(rows)
	end
end

local function to_csv(headers, rows)
	local csv = {}
	if headers and #headers > 0 then
		table.insert(csv, table.concat(headers, ","))
	end

	for _, row in ipairs(rows) do
		table.insert(csv, table.concat(row, ","))
	end
	return table.concat(csv, "\n")
end

local function to_xml(headers, rows)
	local xml = { "<rows>" }
	if headers and #headers > 0 then
		table.insert(xml, "  <headers>")
		for _, header in ipairs(headers) do
			table.insert(xml, "    <header>" .. vim.fn.escape(header, '&<>"') .. "</header>")
		end
		table.insert(xml, "  </headers>")
	end
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

function M.yank_as_format(format, range, with_headers)
	local headers, rows = get_dadbod_rows(range, with_headers)
	if not rows or #rows == 0 then
		vim.notify("No valid rows found in the buffer.", vim.log.levels.WARN)
		return
	end

	local formatted_data
	if format == "json" then
		formatted_data = to_json(headers, rows)
	elseif format == "csv" then
		formatted_data = to_csv(headers, rows)
	elseif format == "xml" then
		formatted_data = to_xml(headers, rows)
	else
		vim.notify("Unsupported format: " .. format, vim.log.levels.ERROR)
		return
	end

	vim.fn.setreg("+", formatted_data)
	vim.notify("Yanked rows as " .. format)
end

function M.setup(user_opts)
	local default_opts = {
		with_headers = true,
	}
	M.opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})

	vim.api.nvim_create_user_command("DBUIYankAsJSON", function(opts)
		M.yank_as_format(
			"json",
			opts.range ~= 0 and { start = opts.line1 - 1, ["end"] = opts.line2 } or nil,
			M.opts.with_headers
		)
	end, { range = true })

	vim.api.nvim_create_user_command("DBUIYankAsCSV", function(opts)
		M.yank_as_format(
			"csv",
			opts.range ~= 0 and { start = opts.line1 - 1, ["end"] = opts.line2 } or nil,
			M.opts.with_headers
		)
	end, { range = true })

	vim.api.nvim_create_user_command("DBUIYankAsXML", function(opts)
		M.yank_as_format(
			"xml",
			opts.range ~= 0 and { start = opts.line1 - 1, ["end"] = opts.line2 } or nil,
			M.opts.with_headers
		)
	end, { range = true })
end

return M
