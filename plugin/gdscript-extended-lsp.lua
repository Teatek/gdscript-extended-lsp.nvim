vim.api.nvim_create_user_command("GodotDoc",
    function(cmd)
        local split_cmd = vim.split(cmd.args, " ", { trimempty = true })
        if #split_cmd >= 1 then
            require("gdscript-extended-lsp").request_doc_class(split_cmd[1])
        end
    end, {
        nargs = "+",
        complete = function(arg_lead, cmd_line, cursor_pos)
            local split_cmd = vim.split(cmd_line, " ", { trimempty = true })
            -- Completion
            if #split_cmd == 1 then
                return require("gdscript-extended-lsp").get_classes()
            end
            -- Default to empty
            return {}
        end
    }
)
