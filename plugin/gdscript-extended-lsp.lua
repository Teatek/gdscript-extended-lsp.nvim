vim.api.nvim_create_user_command("GodotDoc",
    function(cmd)
        local split_cmd = vim.split(cmd.args, " ", { trimempty = true })
        if #split_cmd >= 1 then
            require("gdscript-extended-lsp").request_doc_class(split_cmd[1])
        end
    end, {
        nargs = "+",
        complete = function(arg_lead, cmd_line, cursor_pos)
            local split_cmd = vim.split(cmd_line, " ", { })
            -- Only offer completions for second word
            if #split_cmd ~= 2 then
                return {}
            end

            -- Get current arg
            local arg = string.gsub(cmd_line, ".* ", "^")
            local comp = {}
            -- Completion
            for _, class in ipairs(require("gdscript-extended-lsp").get_classes()) do
                -- Find only classes that begin with current arg
                if string.match(class, arg) then
                    table.insert(comp, class)
                end
            end
            return comp
        end
    }
)
