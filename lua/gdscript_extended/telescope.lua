local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local M = {}

function M.telescope_native_classes(list)
    if #list > 0 then
        pickers.new({},
        {
            prompt_title = "Native classes",
            finder = finders.new_table({
                results = list
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
                map({ "n", "i" } , "<CR>", function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()

                    if selection == nil then
                        print("No class selected.")
                        return
                    end

                    require("gdscript_extended").show_symbol_documentation(selection[1])
                end)
                return true
            end
        }):find()
    else
        print("No classes found. Godot LSP is not initialized.")
    end
end

return M
