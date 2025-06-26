local M = {}

---Get configuration option from the project.godot file with a section and a path
---under that section
---@param section string The section name, written between "[]" in the file
---@param path string The rest of the path, without the section
---@return string | nil value
local function get_project_config_section(section, path)
	local project_godot = vim.fn.readfile("project.godot")

	local in_section = false
	for _, line in ipairs(project_godot) do
		if line:sub(1, 1) == "[" then
			local section_name = line:sub(2, #line - 1)
			if section_name == section then
				in_section = true
			elseif in_section then
				return nil
			end
		end
		if in_section then
			if line:find(path) then
				return line:match(path .. "=(.*)")
			end
		end
	end
	return nil
end

---Get configuration option from the project.godot file, as is written
---@param config_path string The path to the option
---@return string | nil value
local function get_project_config_raw(config_path)
	local top_level = config_path:match("(.-)/")
	if top_level ~= nil then
		local rest = config_path:sub(#top_level + 2)
		return get_project_config_section(top_level, rest)
	end

	local project_godot = vim.fn.readfile("project.godot")

	for _, line in ipairs(project_godot) do
		if line:find(config_path) then
			return line:match(config_path .. "=(.*)")
		end
	end

	return nil
end

---Get configuration option from the project.godot file
---@param config_path string The path to the option
---@return string | nil value
function M.get_project_config(config_path)
	if vim.fn.filereadable("project.godot") == 0 then
		return nil
	end
	local value = get_project_config_raw(config_path)
	if value == nil or value:sub(1, 1) ~= '"' then
		return value
	end

	return value:sub(2, #value - 1)
end

return M
