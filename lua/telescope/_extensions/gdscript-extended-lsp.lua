local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
    error("gdscript-extended-lsp.nvim requires nvim-telescope/telescope.nvim")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local gd_ext = require("gdscript-extended-lsp")

local function telescope_classes()
    local classes = gd_ext.get_classes()
    if #classes > 0 then
        pickers.new({},
            {
                prompt_title = "Godot Classes",
                finder = finders.new_table({
                    results = classes
                }),
                sorter = conf.generic_sorter({}),
                attach_mappings = function(prompt_bufnr, map)
                    map({ "n", "i" }, "<CR>", function()
                        actions.close(prompt_bufnr)
                        local selection = action_state.get_selected_entry()

                        if selection == nil then
                            vim.notify("No class selected.", vim.log.levels.ERROR)
                            return
                        end

                        gd_ext.request_doc_class(selection[1])
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
        class = telescope_classes,
    },
})
