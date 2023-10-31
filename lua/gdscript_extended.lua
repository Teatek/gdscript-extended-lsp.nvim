local config = require("gdscript_extended.config")
local utils = require("gdscript_extended.utils")
local telescope = require("gdscript_extended.telescope")

local M = {}

local client_id = -1

local native_class_list = {}

function M.parse_lsp_data_to_md()
    local result = {}
    return result
end


function M.show_symbol_documentation(symbol)
    local bufnr = -1
    for _, v in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(v) and string.find(vim.api.nvim_buf_get_name(v), symbol .. config.options.doc_file_extension) then
          bufnr = v
        break
      end
    end
    if bufnr == -1 then
        bufnr = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
        vim.api.nvim_buf_set_name(bufnr, symbol .. config.options.doc_file_extension)

        -- request to LSP server
        local attached_buffers = vim.lsp.get_buffers_by_client_id(client_id)
        if #attached_buffers > 0 then
            vim.lsp.buf_request(attached_buffers[1], "textDocument/nativeSymbol", {
                native_class = symbol, symbol_name = symbol
            }, function (err, result, _, _)
                if result ~= nil then
                    local md_lines = vim.lsp.util.convert_input_to_markdown_lines(result.documentation)
                    md_lines[3] = "# Description"
                    table.insert(md_lines, 4, "")
                    vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, {result.detail})
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)

                    local properties = {}
                    for _, v in pairs(result.children) do
                        if v.kind == 7 then
                            md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                            local str_clean = string.gsub(v.detail, "var ", "")
                            local prop = vim.split(string.gsub(str_clean, v.native_class .. ".", ""), ": ")
                            table.insert(properties, {info = {prop[2] .. " " .. prop[1]}, desc = md_lines})
                            if #properties == 1 then
                                vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"# Properties", ""})
                            end
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, properties[#properties].info)
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {""})
                        end
                    end

                    -- methods
                    local methods = {}
                    for _, v in pairs(result.children) do
                        if v.kind == 6 then
                            md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                            local str_clean = string.gsub(v.detail, "func ", "")
                            str_clean = string.gsub(str_clean, v.native_class .. ".", "")
                            local prop = vim.split(str_clean, " --> ")
                            table.insert(methods, {info = {prop[2] .. " " .. prop[1]}, desc = md_lines})
                            if #methods == 1 then
                                vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"# Methods", ""})
                            end
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, methods[#methods].info)
                        end
                    end

                    -- signals
                    local has_signals = false
                    for _, v in pairs(result.children) do
                        if v.kind == 24 then
                            if not has_signals then
                                vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"", "# Signals", ""})
                                has_signals = true
                            end
                            md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                            local str_clean = string.gsub(v.detail, "func " .. v.native_class .. ".", "")
                            str_clean = string.gsub(str_clean, " --> void", "")
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {str_clean})
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {""})
                        end
                    end

                    -- enums
                    local has_enums = false
                    for _, v in pairs(result.children) do
                        if v.kind == 14 then
                            if not has_enums then
                                vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"", "# Enumerations", ""})
                                has_enums = true
                            end
                            md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                            local str_clean = string.gsub(v.detail, "const ", "")
                            local prop = vim.split(string.gsub(str_clean, v.native_class .. ".", ""), ": ")
                            local prop_value = vim.split(prop[2], " = ")
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {prop_value[1] .. " " .. prop[1] .. " = " .. prop_value[2]})
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {""})
                        end
                    end

                    -- property descriptions
                    if #properties > 0 then
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"", "# Property Descriptions", ""})
                    end
                    for _, v in pairs(properties) do
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, v.info)
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, v.desc)
                    end

                    -- method descriptions
                    if #methods > 0 then
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"", "# Method Descriptions", ""})
                    end
                    for _, v in pairs(methods) do
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, v.info)
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, v.desc)
                    end
                    -- set buffer readonly option
                    vim.api.nvim_buf_set_option(bufnr, "readonly", true)
                    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)


                    if vim.api.nvim_win_get_config(0).relative == '' then
                        -- current window isn't floating
                        vim.api.nvim_open_win(bufnr, true, utils.floating_window_opts())
                    else
                        vim.api.nvim_win_set_buf(0, bufnr)
                    end

                    -- quit buffer mapping
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', config.options.keymaps.cursor,
                    '<Cmd>GodotDocCursor<CR>',
                    {noremap = true, silent = true}
                    )

                    for _, value in pairs(config.options.keymaps.close) do
                        vim.api.nvim_buf_set_keymap(bufnr, 'n', value,
                        '<Cmd>lua vim.api.nvim_win_close(' .. 0 .. ', true)<CR>',
                        {noremap = true, silent = true}
                        )
                    end
                else
                    print("Native class not found.")
                end
            end)
        end
    else
        if vim.api.nvim_win_get_config(0).relative == '' then
            -- current window isn't floating
            vim.api.nvim_open_win(bufnr, true, utils.floating_window_opts())
        else
            vim.api.nvim_win_set_buf(0, bufnr)
        end
    end

    return nil
end

function M.setup(opts)
    -- user plugin config
    config.setup(opts)

    -- LSP Setup
    require('lspconfig').gdscript.setup({
        on_attach = function(client, bufnr)
            config.options.on_attach()
            if client_id == -1 then
                client_id = client.id
            end
        end,
        handlers = {
            ["gdscript/capabilities"] = function(_, result, _)
                native_class_list = {}
                for _, v in pairs(result.native_classes) do
                    table.insert(native_class_list, v.name)
                end

                function CompletionClasses()
                    return vim.fn.join(native_class_list, '\n')
                end
                -- user commands
                vim.api.nvim_create_user_command("GodotDocSymbol", function(cmd)
                    M.show_symbol_documentation(cmd.args)
                end,
                {
                    nargs = 1,
                    complete = 'custom,v:lua.CompletionClasses',
                })
            end
        }
    })

    -- User Commands
    vim.api.nvim_create_user_command("GodotDocCursor", function()
        local word = vim.fn.expand("<cword>")
        M.show_symbol_documentation(word)
    end, {})

    -- Telescope User Command
    local telescope_installed = pcall(require, 'telescope')
    if telescope_installed then
        vim.api.nvim_create_user_command("GodotDocTelescope", function()
            telescope.telescope_native_classes(native_class_list)
        end, {})
    end
end

return M