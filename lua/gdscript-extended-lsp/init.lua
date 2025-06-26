local M = {}

-- @type gdscript_extended.Defaults
local defaults = {
	doc_file_extension = ".txt",
	view_type = "vsplit",
	split_side = false,
	keymaps = {
		declaration = "gd",
		close = { "q", "<Esc>" },
	},
	floating_win_size = 0.8,
	picker = "telescope",
}

M.options = defaults

local client_id = -1

local working_dir = ""

local is_doc_cursor = false

local is_doc_cursor_double_search = false

local search_doc_location = ""

local native_class_list = {}

local scratch_buf_name = "lsp_search.gd"

---Floating window settings
---@return table
local function floating_window_opts()
	local width = vim.api.nvim_get_option_value("columns", {})
	local height = vim.api.nvim_get_option_value("lines", {})

	-- calculate our floating window size
	local win_height = math.ceil(height * M.options.floating_win_size - 4)
	local win_width = math.ceil(width * M.options.floating_win_size)
	-- and its starting position
	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)

	return {
		relative = "editor",
		width = win_width,
		height = win_height,
		col = col,
		row = row,
		style = "minimal",
	}
end

--- Get list of classes
---@return string[]
function M.get_classes()
	return native_class_list
end

--- Set conceal options for a window
---@param win integer Window handle, or 0 for current window
local function set_win_conceal(win)
	vim.api.nvim_set_option_value("concealcursor", "n", { win = win })
	vim.api.nvim_set_option_value("conceallevel", 1, { win = win })
end

--- Get buffer handle by name
---@param symbol_name string Symbol name
---@return integer bufnr Buffer handle
local function get_buffer_for_name(symbol_name)
	local filename = symbol_name .. M.options.doc_file_extension
	local bufnr = -1
	for _, v in pairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(v) and string.find(vim.api.nvim_buf_get_name(v), filename) then
			bufnr = v
			break
		end
	end
	return bufnr
end

--- Add section content inside buffer handle
---@param bufnr integer Buffer handle, or 0 for current buffer
---@param title string Title for section
---@param list table Section content
local function add_section_with_description(bufnr, title, list)
	local is_title_set = false
	for _, v in pairs(list) do
		if #v.desc > 0 then
			if not is_title_set then
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "# " .. title .. " Descriptions", "" })
				is_title_set = true
			end
			vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "```gdscript", v.info, "```" })
			vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, v.desc)
			vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "" })
		end
	end
end

---@param content string Content
local function parse_markdown(content)
	-- TODO: Clean this function
	content = string.gsub(content, "%[b]", "**")
	content = string.gsub(content, "%[/b]", "**")
	content = string.gsub(content, "%[code]", "`")
	content = string.gsub(content, "%[/code]", "`")
	content = string.gsub(content, "%\t\t\t\t", "\n")
	content = string.gsub(content, "%\t\t", "\n")
	content = string.gsub(content, "%\t", "")
	content = string.gsub(content, "%[codeblocks]", "")
	content = string.gsub(content, "%[/codeblocks]", "")
	content = string.gsub(content, "%[gdscript]", "```gdscript")
	content = string.gsub(content, "%[/gdscript]", "```")
	content = string.gsub(content, "%[csharp]", "```csharp")
	content = string.gsub(content, "%[/csharp]", "```")
	content = string.gsub(content, "%[%w+]", function(w)
		return "`" .. string.sub(w, 2, string.len(w) - 1) .. "`"
	end)
	return content
end

function M.request_doc_class(symbol)
	local client = vim.lsp.get_client_by_id(client_id)
	if client ~= nil then
		-- Create an in-memory scratch buffer
		local scratch_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(scratch_buf, scratch_buf_name)
		vim.api.nvim_set_option_value("filetype", "gdscript", { buf = scratch_buf })
		vim.lsp.buf_attach_client(scratch_buf, client_id)
		vim.api.nvim_buf_set_lines(scratch_buf, -2, -1, false, { "extends " .. symbol })

		-- After the LSP attaches, send a declaration request
		vim.defer_fn(function()
			client:request("textDocument/declaration", {
				position = { character = 9, line = 0 },
				textDocument = { uri = client.workspace_folders[1].uri .. "/" .. scratch_buf_name },
			}, function()
				vim.api.nvim_buf_delete(scratch_buf, {})
			end, scratch_buf)
		end, 100)
	else
		vim.notify("Godot LSP is not initialized", vim.log.levels.ERROR)
	end
end

local function open_documentation_view(bufnr)
	if M.options.view_type == "vsplit" then
		vim.cmd(":vsplit")
		if M.options.split_side == false then
			vim.cmd(":wincmd l")
		end
	elseif M.options.view_type == "split" then
		vim.cmd(":split")
		if M.options.split_side == false then
			vim.cmd(":wincmd j")
		end
	elseif M.options.view_type == "tab" then
		vim.cmd(":tab split")
		vim.api.nvim_win_set_buf(0, bufnr)
	elseif M.options.view_type == "floating" then
		if vim.api.nvim_win_get_config(0).relative == "" then
			-- current window isn't floating
			local win = vim.api.nvim_open_win(bufnr, true, floating_window_opts())
		end
	end
	vim.api.nvim_win_set_buf(0, bufnr)
end

local function show_native_symbol_handler(ctx, result, params)
	if result then
		local bufnr = get_buffer_for_name(result.native_class)
		if bufnr == -1 then
			if result.native_class ~= result.name then
				is_doc_cursor = true
				if result.name == string.upper(result.name) then
					search_doc_location = result.name
					is_doc_cursor_double_search = false
				else
					search_doc_location = string.gsub(result.detail, result.native_class .. "%.", "")
					is_doc_cursor_double_search = true
				end
				M.request_doc_class(result.native_class)
			else
				-- create documentation using LSP server
				local filename = result.native_class .. M.options.doc_file_extension
				bufnr = vim.api.nvim_create_buf(true, true)

				vim.api.nvim_buf_set_name(bufnr, filename)
				result.documentation = parse_markdown(result.documentation)
				local md_lines = vim.lsp.util.convert_input_to_markdown_lines(result.documentation)
				if #md_lines > 0 then
					md_lines[3] = "# Description"
					table.insert(md_lines, 4, "")
				end
				local title = string.gsub(result.detail, "<Native> ", "")
				vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { "```gdscript", title, "```" })
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "" })

				local properties = {}
				for _, v in pairs(result.children) do
					if v.kind == 7 then
						v.documentation = parse_markdown(v.documentation)
						md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
						local s = string.gsub(v.detail, v.native_class .. "%.", "")
						table.insert(properties, { info = s, desc = md_lines })
						if #properties == 1 then
							vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "# Properties", "```gdscript" })
						end
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { properties[#properties].info })
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "" })
					end
				end
				if #properties > 0 then
					vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "```" })
				end

				-- methods
				local methods = {}
				for _, v in pairs(result.children) do
					if v.kind == 6 then
						v.documentation = parse_markdown(v.documentation)
						md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
						local s = string.gsub(v.detail, v.native_class .. "%.", "")
						table.insert(methods, { info = s, desc = md_lines })
						if #methods == 1 then
							vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "# Methods" })
						end
						vim.api.nvim_buf_set_lines(
							bufnr,
							-1,
							-1,
							true,
							{ "```gdscript", methods[#methods].info, "```" }
						)
					end
				end

				-- signals
				local has_signals = false
				for _, v in pairs(result.children) do
					if v.kind == 24 then
						if not has_signals then
							vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "# Signals" })
							has_signals = true
						else
							vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "" })
						end
						v.documentation = parse_markdown(v.documentation)
						md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
						local s = string.gsub(v.detail, v.native_class .. "%.", "")
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "```gdscript", s, "```" })
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "" })
					end
				end

				-- enums
				local has_enums = false
				for _, v in pairs(result.children) do
					if v.kind == 14 then
						if not has_enums then
							vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "# Enumerations" })
							has_enums = true
						end
						v.documentation = parse_markdown(v.documentation)
						md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
						local s = string.gsub(v.detail, v.native_class .. "%.", "")
						s = string.gsub(s, "const", "var")
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "```gdscript", s, "```" })
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
						vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "" })
					end
				end

				-- property descriptions
				add_section_with_description(bufnr, "Property", properties)

				-- method descriptions
				add_section_with_description(bufnr, "Method", methods)

				-- set buffer readonly option
				vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
				vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

				-- FIXME : Use mapping set by user. (Can't do it for unknown reasons)
				vim.keymap.set("n", "gf", function()
					M.request_doc_class(vim.fn.expand("<cword>"))
				end, { buffer = bufnr })

				-- quit buffer mapping
				for _, value in pairs(M.options.keymaps.close) do
					vim.api.nvim_buf_set_keymap(
						bufnr,
						"n",
						value,
						"<Cmd>lua vim.api.nvim_win_close(" .. 0 .. ", true)<CR>",
						{ noremap = true, silent = true }
					)
				end

				open_documentation_view(bufnr)
				vim.bo[bufnr].filetype = "markdown"
				set_win_conceal(0)

				if is_doc_cursor then
					-- Search twice to get the description
					local line_number = vim.fn.search(search_doc_location)
					if is_doc_cursor_double_search then
						line_number = vim.fn.search(search_doc_location)
					end
					if line_number ~= 0 then
						vim.api.nvim_win_set_cursor(0, { line_number, 0 })
					end
					is_doc_cursor = false
				end
			end
		else
			-- FIXME: If the buffer is opened in a window: jump cursor instead of opening new window
			open_documentation_view(bufnr)
			set_win_conceal(0)
			if result.native_class ~= result.name then
				if result.name == string.upper(result.name) then
					search_doc_location = result.name
					is_doc_cursor_double_search = false
				else
					search_doc_location = string.gsub(result.detail, result.native_class .. "%.", "")
					is_doc_cursor_double_search = true
				end
				vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- line 1, column 0
				-- Search twice to get the description
				local line_number = vim.fn.search(search_doc_location)
				if is_doc_cursor_double_search then
					line_number = vim.fn.search(search_doc_location)
				end
				if line_number ~= 0 then
					vim.api.nvim_win_set_cursor(0, { line_number, 0 })
				end
			else
				vim.api.nvim_win_set_cursor(0, { 1, 0 })
			end
		end
	end
end

local function set_attach()
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("gdscript.extended.lsp", {}),
		callback = function(args)
			local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
			if client.name ~= "gdscript" then
				return
			end

			client_id = args.data.client_id
			working_dir = client.root_dir

			if client:supports_method("gdscript/capabilities") then
				-- List of all the classes
				vim.lsp.handlers["gdscript/capabilities"] = function(_, result, _)
					-- add all the classes found
					-- TODO: Only update when changing godot project
					native_class_list = {}
					for _, v in pairs(result.native_classes) do
						table.insert(native_class_list, v.name)
					end
				end
			end

			if client:supports_method("gdscript/show_native_symbol") then
				-- List of all the classes
				vim.lsp.handlers["gdscript/show_native_symbol"] = show_native_symbol_handler
			end

			-- Use declaration (in case we want the doc inside of godot)
			vim.keymap.set("n", M.options.keymaps.declaration, function()
				vim.lsp.buf.declaration()
			end, { buffer = 0 })
		end,
	})
end

local function better_gf()
	local project_name = M.get_project_config("application/config/name")

	local user_data_dir = ""
	if vim.fn.has("unix") == 1 then
		user_data_dir = vim.fn.expand("~") .. "/.local/share/"
	elseif vim.fn.has("win32") == 1 then
		user_data_dir = vim.fn.expand("%APPDATA%")
	end

	local project_data_dir

	local use_custom_dir = M.get_project_config("application/config/use_custom_user_dir")
	if use_custom_dir == "true" then
		local custom_dir_name = M.get_project_config("application/config/custom_user_dir_name")
		if custom_dir_name ~= nil then
			project_data_dir = user_data_dir .. custom_dir_name .. "/"
		else
			project_data_dir = user_data_dir .. project_name .. "/"
		end
	else
		project_data_dir = user_data_dir .. "godot/app_userdata/" .. project_name .. "/"
	end

	vim.keymap.set("n", "gf", function()
		local original_file = vim.fn.expand("<cfile>")
		local file = original_file:gsub("^res://", "")
		file = file:gsub("^user://", project_data_dir)

		vim.cmd.edit(file)
	end)
end

-- @param opts gdscript_extended.Defaults
function M.setup(opts)
	-- user plugin config
	M.options = vim.tbl_deep_extend("force", defaults, opts or {})

	set_attach()
end

function M.pick()
	local picker = require("gdscript-extended-lsp.picker")
	if M.options.picker == "telescope" then
		picker.telescope()
	elseif M.options.picker == "snacks" then
		picker.snacks()
	else
		vim.notify("'" .. M.options.picker .. "' Not supported", vim.log.levels.ERROR)
	end
end

---Get configuration option from the project.godot file
---@param config_path string The path to the option
---@return string | nil value
function M.get_project_config(config_path)
	return require("gdscript-extended-lsp.project").get_project_config(config_path)
end

better_gf()

return M
