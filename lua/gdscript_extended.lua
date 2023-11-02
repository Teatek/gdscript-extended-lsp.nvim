local config = require("gdscript_extended.config")
local utils = require("gdscript_extended.utils")

local M = {}

local client_id = -1

local native_class_list = {}

--- Get list of classes
---@return string[]
function M.get_native_classes()
    return native_class_list
end

--- Set conceal options for a window
---@param win integer Window handle, or 0 for current window
function M.set_win_conceal(win)
    vim.api.nvim_win_set_option(win, "concealcursor", "n")
    vim.api.nvim_win_set_option(win, "conceallevel", 2)
end

--- Get buffer handle by name
---@param symbol_name string Symbol name
---@return integer bufnr Buffer handle
function M.get_buffer_for_name(symbol_name)
    local filename = symbol_name .. config.options.doc_file_extension
    local bufnr = -1
    for _, v in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(v) and string.find(vim.api.nvim_buf_get_name(v), filename) then
            bufnr = v
            break
        end
    end
    return bufnr
end


--- Set documentation content to a buffer for a symbol name
---@param bufnr integer Buffer handle, or 0 for current buffer
---@param symbol string Symbol name
function M.add_content_to_buffer(bufnr, symbol)
    -- TODO: clean this function
    local attached_buffers = vim.lsp.get_buffers_by_client_id(client_id)
    if #attached_buffers > 0 then
        vim.lsp.buf_request(attached_buffers[1], "textDocument/nativeSymbol", {
            native_class = symbol, symbol_name = symbol
        }, function (_, result, _, _)
            if result ~= nil then
                local md_lines = vim.lsp.util.convert_input_to_markdown_lines(result.documentation)
                md_lines[3] = "# Description"
                table.insert(md_lines, 4, "")
                local title = string.gsub(result.detail, "<Native> ", "")
                vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, {"```gdscript", title, "```"})
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)

                local properties = {}
                for _, v in pairs(result.children) do
                    if v.kind == 7 then
                        md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                        local s = string.gsub(v.detail, v.native_class .. ".", "")
                        table.insert(properties, {info = s, desc = md_lines})
                        if #properties == 1 then
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"# Properties", "```gdscript"})
                        end
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {properties[#properties].info})
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {""})
                    end
                end
                if #properties > 0 then
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"```"})
                end

                -- methods
                local methods = {}
                for _, v in pairs(result.children) do
                    if v.kind == 6 then
                        md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                        local s = string.gsub(v.detail, v.native_class .. ".", "")
                        table.insert(methods, {info = s, desc = md_lines})
                        if #methods == 1 then
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"# Methods"})
                        end
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"```gdscript", methods[#methods].info, "```"})
                    end
                end

                -- signals
                local has_signals = false
                for _, v in pairs(result.children) do
                    if v.kind == 24 then
                        if not has_signals then
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"", "# Signals"})
                            has_signals = true
                        end
                        md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                        local s = string.gsub(v.detail, v.native_class .. ".", "")
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"```gdscript", s, "```"})
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {""})
                    end
                end

                -- enums
                local has_enums = false
                for _, v in pairs(result.children) do
                    if v.kind == 14 then
                        if not has_enums then
                            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"", "# Enumerations"})
                            has_enums = true
                        end
                        md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                        local s = string.gsub(v.detail, v.native_class .. ".", "")
                        s = string.gsub(s, "const", "var")
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"```gdscript", s, "```"})
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {""})
                    end
                end

                -- property descriptions
                M.add_section_with_description(bufnr, "Property", properties)

                -- method descriptions
                M.add_section_with_description(bufnr, "Method", methods)

                -- set buffer readonly option
                vim.api.nvim_buf_set_option(bufnr, "readonly", true)
                vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

                -- user config function
                config.options.doc_keymaps.user_config()

                -- quit buffer mapping
                for _, value in pairs(config.options.doc_keymaps.close) do
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
end

--- Add section content inside buffer handle
---@param bufnr integer Buffer handle, or 0 for current buffer
---@param title string Title for section
---@param list table Section content
function M.add_section_with_description(bufnr, title, list)
    if #list > 0 then
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"", "# ".. title .. "Descriptions", ""})
    end
    for _, v in pairs(list) do
        if #v.desc > 0 then
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, {"```gdscript", v.info, "```"})
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, v.desc)
        end
    end
end

--- Create a documentation buffer for a symbol
---@param symbol string Symbol name
function M.create_doc_buffer(symbol)
    local bufnr = M.get_buffer_for_name(symbol)
    if bufnr == -1 then
        local filename = symbol .. config.options.doc_file_extension
        bufnr = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
        vim.api.nvim_buf_set_name(bufnr, filename)
        -- request to LSP server
        M.add_content_to_buffer(bufnr, symbol)
    end
    return bufnr
end


--- Open documentation window inside a new tab
---@param symbol string Symbol name
function M.open_doc_in_new_tab(symbol)
    vim.cmd(':tab split')
    vim.api.nvim_win_set_buf(0, M.create_doc_buffer(symbol))
    M.set_win_conceal(0)
end

--- Open documentation window inside a new vsplit window
---@param symbol string Symbol name
---@param right boolean Open documentation on the left or right
function M.open_doc_in_vsplit_win(symbol, right)
    vim.cmd(':vsplit')
    if right then
        vim.cmd(':wincmd l')
    end
    vim.api.nvim_win_set_buf(0, M.create_doc_buffer(symbol))
    M.set_win_conceal(0)
end

--- Open documentation window inside a new split window
---@param symbol string Symbol name
---@param top boolean Open documentation on the bottom or top
function M.open_doc_in_split_win(symbol, top)
    vim.cmd(':split')
    if top then
        vim.cmd(':wincmd k')
    end
    vim.api.nvim_win_set_buf(0, M.create_doc_buffer(symbol))
    M.set_win_conceal(0)
end

--- Open documentation window inside a new floating window
---@param symbol string Symbol name
function M.open_doc_in_floating_win(symbol)
    local bufnr = M.create_doc_buffer(symbol)
    if vim.api.nvim_win_get_config(0).relative == '' then
        -- current window isn't floating
        local win = vim.api.nvim_open_win(bufnr, true, utils.floating_window_opts())
        M.set_win_conceal(win)
    else
        vim.api.nvim_win_set_buf(0, bufnr)
    end
end

--- Open documentation window inside the current window
---@param symbol string Symbol name
function M.open_doc_in_current_win(symbol)
    local bufnr = M.create_doc_buffer(symbol)
    vim.api.nvim_win_set_buf(0, bufnr)
    M.set_win_conceal(0)
end

function M.setup(opts)
    -- user plugin config
    config.setup(opts)

    -- LSP Setup
    require('lspconfig').gdscript.setup({
        on_attach = function(client, _)
            config.options.on_attach()
            if client_id == -1 then
                client_id = client.id
            end
        end,
        handlers = {
            ["gdscript/capabilities"] = function(_, result, _)
                -- add all the classes found
                native_class_list = {}
                for _, v in pairs(result.native_classes) do
                    table.insert(native_class_list, v.name)
                end
            end
        }
    })
end

return M
