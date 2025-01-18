local M = {}

local function get_dadbod_rows()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local rows = {}

	local data_start = false
	for _, line in ipairs(lines) do
		if data_start then
			table.insert(rows, vim.split(line, "|", { plain = true, trimempty = true }))
		elseif line:match("^%+%-") then
			data_start = true
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

function M.yank_as_format(format)
	local rows = get_dadbod_rows()
	if not rows or #rows == 0 then
		vim.notify("No rows found in the buffer.", vim.log.levels.WARN)
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
	vim.api.nvim_create_user_command("DadbodYankAsJSON", function()
		M.yank_as_format("json")
	end, {})
	vim.api.nvim_create_user_command("DadbodYankAsCSV", function()
		M.yank_as_format("csv")
	end, {})
	vim.api.nvim_create_user_command("DadbodYankAsXML", function()
		M.yank_as_format("xml")
	end, {})
end

return M
