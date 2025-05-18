local M = {}
local gd_ext = require("gdscript-extended-lsp")

local function class_finder()
    local items = {}

    for i, class in ipairs(gd_ext.get_classes()) do
        local item = {
            -- score = 0,
            text = class,
            value = class,
            name = class,
            idx = i,
        }

        table.insert(items, item)
    end
    return items
end

function M.snacks()
    local snacks_ok, snacks = pcall(require, "snacks")

    if not (snacks_ok and snacks and snacks.picker) then
        vim.notify("snacks.nvim not found", vim.log.levels.WARN)
        return
    end

    snacks.picker.pick({
        title = "Godot Classes",
        preview = "none",
        layout = {
            preset = "vscode",
        },
        format = function(item, _)
            return {
                { item.text },
            }
        end,
        finder = class_finder,
        -- layout = M.config.layout,
        -- format = format_session_item,
        confirm = function(self, item)
            self:close()
            gd_ext.request_doc_class(item.value)
        end,
    })
end

function M.telescope()
    local has_telescope, _ = pcall(require, "telescope")

    if not has_telescope then
        vim.notify("Telescope not found", vim.log.levels.ERROR)
        return
    end

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values

    local classes = gd_ext.get_classes()
    if #classes > 0 then
        pickers
            .new({}, {
                prompt_title = "Godot Classes",
                finder = finders.new_table({
                    results = classes,
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
                end,
            })
            :find()
    else
        vim.notify("No classes found. Godot LSP is not initialized.")
    end
end

return M
