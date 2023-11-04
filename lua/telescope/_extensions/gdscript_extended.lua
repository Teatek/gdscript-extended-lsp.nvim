local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
    error("gdscript-extended-lsp.nvim requires nvim-telescope/telescope.nvim")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local gd_ext = require("gdscript_extended")

local function native_classes_default()
    local classes = gd_ext.get_native_classes()
    if #classes > 0 then
        pickers.new({},
        {
            prompt_title = "Godot Classes",
            finder = finders.new_table({
                results = classes
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                map({ "n", "i" } , "<CR>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        vim.notify("No class selected.", vim.log.levels.ERROR)
                        return
                    end

                    gd_ext.open_doc_in_current_win(selection[1])
                end)
                map({ "n", "i" } , "<C-t>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        vim.notify("No class selected.", vim.log.levels.ERROR)
                        return
                    end

                    gd_ext.open_doc_in_new_tab(selection[1])
                end)

                map({ "n", "i" } , "<C-f>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        vim.notify("No class selected.", vim.log.levels.ERROR)
                        return
                    end

                    gd_ext.open_doc_in_floating_win(selection[1])
                end)

                map({ "n", "i" } , "<C-x>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        vim.notify("No class selected.", vim.log.levels.ERROR)
                        return
                    end

                    gd_ext.open_doc_in_split_win(selection[1], true)
                end)

                map({ "n", "i" } , "<C-v>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        vim.notify("No class selected.", vim.log.levels.ERROR)
                        return
                    end

                    gd_ext.open_doc_in_vsplit_win(selection[1], true)
                end)

                return true
            end
        }):find()
    else
        vim.notify("No classes found. Godot LSP is not initialized.")
    end
end

local function native_classes_tab()
    local classes = gd_ext.get_native_classes()
    if #classes > 0 then
        pickers.new({},
        {
            prompt_title = "Godot Classes",
            finder = finders.new_table({
                results = classes
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                map({ "n", "i" } , "<CR>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        vim.notify("No class selected.", vim.log.levels.ERROR)
                        return
                    end

                    gd_ext.open_doc_in_new_tab(selection[1])
                end)
                return true
            end
        }):find()
    else
        vim.notify("No classes found. Godot LSP is not initialized.", vim.log.levels.ERROR)
    end
end

local function native_classes_float()
    local classes = gd_ext.get_native_classes()
    if #classes > 0 then
        pickers.new({},
        {
            prompt_title = "Godot Classes",
            finder = finders.new_table({
                results = classes
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                map({ "n", "i" } , "<CR>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        vim.notify("No class selected.")
                        return
                    end

                    gd_ext.open_doc_in_floating_win(selection[1])
                end)
                return true
            end
        }):find()
    else
        vim.notify("No classes found. Godot LSP is not initialized.")
    end
end

local function native_classes_split()
    local classes = gd_ext.get_native_classes()
    if #classes > 0 then
        pickers.new({},
        {
            prompt_title = "Godot Classes",
            finder = finders.new_table({
                results = classes
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                map({ "n", "i" } , "<CR>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        vim.notify("No class selected.")
                        return
                    end

                    gd_ext.open_doc_in_split_win(selection[1], true)
                end)
                return true
            end
        }):find()
    else
        vim.notify("No classes found. Godot LSP is not initialized.")
    end
end

local function native_classes_vsplit()
    local classes = gd_ext.get_native_classes()
    if #classes > 0 then
        pickers.new({},
        {
            prompt_title = "Godot Classes",
            finder = finders.new_table({
                results = classes
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                map({ "n", "i" } , "<CR>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        vim.notify("No class selected.")
                        return
                    end

                    gd_ext.open_doc_in_vsplit_win(selection[1], true)
                end)
                return true
            end
        }):find()
    else
        vim.notify("No classes found. Godot LSP is not initialized.")
    end
end

return telescope.register_extension({
    exports = {
        default = native_classes_default,
        float = native_classes_float,
        split = native_classes_split,
        vsplit = native_classes_vsplit,
        tab = native_classes_tab,
    },
})
