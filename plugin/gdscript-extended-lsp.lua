vim.api.nvim_create_user_command("Godot",
    function(cmd)
        local split_cmd = vim.split(cmd.args, " ", { trimempty = true })
        if #split_cmd >= 2 then
            if split_cmd[1] == "doc" then
                require("gdscript-extended-lsp").request_doc_class(split_cmd[2])
            end
        end
    end, {
        nargs = "+",
        complete = function(arg_lead, cmd_line, cursor_pos)
            local basic_operations = { "doc" }

            local split_cmd = vim.split(cmd_line, " ", { trimempty = true })
            -- Completion for the first argument
            if #split_cmd == 1 then
                return basic_operations
            end

            -- Completion for the 'doc' argument
            if #split_cmd == 2 and split_cmd[2] == basic_operations[1] then
                return require("gdscript-extended-lsp").get_classes()
            end

            -- Default to empty
            return {}
        end
    }
)
