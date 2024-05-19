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
local function set_win_conceal(win)
    vim.api.nvim_win_set_option(win, "concealcursor", "n")
    vim.api.nvim_win_set_option(win, "conceallevel", 2)
end

--- Get buffer handle by name
---@param symbol_name string Symbol name
---@return integer bufnr Buffer handle
local function get_buffer_for_name(symbol_name)
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

--- Add section content inside buffer handle
---@param bufnr integer Buffer handle, or 0 for current buffer
---@param title string Title for section
---@param list table Section content
local function add_section_with_description(bufnr, title, list)
    local is_title_set = false
    for _, v in pairs(list) do
        if #v.desc > 0 then
            if not is_title_set then
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "# " .. title .. " Descriptions", "" })
                is_title_set = true
            end
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "```gdscript", v.info, "```" })
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, v.desc)
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "" })
        end
    end
end

---@param content string Content
local function parse_markdown(content)
    -- TODO: Clean this function
    content = string.gsub(content, "%[b]", "**")
    content = string.gsub(content, "%[/b]", "**")
    content = string.gsub(content, "%[code]", "`")
    content = string.gsub(content, "%[/code]", "`")
    content = string.gsub(content, "%\t\t\t\t", "\n")
    content = string.gsub(content, "%\t\t", "\n")
    content = string.gsub(content, "%\t", "")
    content = string.gsub(content, "%[codeblocks]", "")
    content = string.gsub(content, "%[/codeblocks]", "")
    content = string.gsub(content, "%[gdscript]", "```gdscript")
    content = string.gsub(content, "%[/gdscript]", "```")
    content = string.gsub(content, "%[csharp]", "```csharp")
    content = string.gsub(content, "%[/csharp]", "```")
    content = string.gsub(content, "%[%w+]", function(w)
        return "`" .. string.sub(w, 2, string.len(w) - 1) .. "`"
    end)
    return content
end

--- Create documentation buffer for a symbol name
---@param symbol string Symbol name
---@return integer bufnr Buffer handle, -1 if it fails to get the documentation
local function add_content_to_buffer(symbol)
    -- TODO: clean this function
    local attached_buffers = vim.lsp.get_buffers_by_client_id(client_id)
    local bufnr = -1
    if #attached_buffers > 0 then
        -- Wait 5s max for a result (maybe change this for a smaller value in the future)
        local res = vim.lsp.buf_request_sync(attached_buffers[1], "textDocument/nativeSymbol", {
            native_class = symbol,
            symbol_name = symbol,
        }, 5 * 1000)
        if res ~= nil and res[1].result ~= nil then
            local result = res[1].result
            -- Create buffer since the request is successful
            local filename = symbol .. config.options.doc_file_extension
            bufnr = vim.api.nvim_create_buf(true, true)
            vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
            vim.api.nvim_buf_set_name(bufnr, filename)

            result.documentation = parse_markdown(result.documentation)
            local md_lines = vim.lsp.util.convert_input_to_markdown_lines(result.documentation)
            if #md_lines > 0 then
                md_lines[3] = "# Description"
                table.insert(md_lines, 4, "")
            end
            local title = string.gsub(result.detail, "<Native> ", "")
            vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { "```gdscript", title, "```" })
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "" })

            local properties = {}
            for _, v in pairs(result.children) do
                if v.kind == 7 then
                    v.documentation = parse_markdown(v.documentation)
                    md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                    local s = string.gsub(v.detail, v.native_class .. "%.", "")
                    table.insert(properties, { info = s, desc = md_lines })
                    if #properties == 1 then
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "# Properties", "```gdscript" })
                    end
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { properties[#properties].info })
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "" })
                end
            end
            if #properties > 0 then
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "```" })
            end

            -- methods
            local methods = {}
            for _, v in pairs(result.children) do
                if v.kind == 6 then
                    v.documentation = parse_markdown(v.documentation)
                    md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                    local s = string.gsub(v.detail, v.native_class .. "%.", "")
                    table.insert(methods, { info = s, desc = md_lines })
                    if #methods == 1 then
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "# Methods" })
                    end
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "```gdscript", methods[#methods].info, "```" })
                end
            end

            -- signals
            local has_signals = false
            for _, v in pairs(result.children) do
                if v.kind == 24 then
                    if not has_signals then
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "# Signals" })
                        has_signals = true
                    else
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "" })
                    end
                    v.documentation = parse_markdown(v.documentation)
                    md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                    local s = string.gsub(v.detail, v.native_class .. "%.", "")
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "```gdscript", s, "```" })
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "" })
                end
            end

            -- enums
            local has_enums = false
            for _, v in pairs(result.children) do
                if v.kind == 14 then
                    if not has_enums then
                        vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "", "# Enumerations" })
                        has_enums = true
                    end
                    v.documentation = parse_markdown(v.documentation)
                    md_lines = vim.lsp.util.convert_input_to_markdown_lines(v.documentation)
                    local s = string.gsub(v.detail, v.native_class .. "%.", "")
                    s = string.gsub(s, "const", "var")
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "```gdscript", s, "```" })
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, md_lines)
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { "" })
                end
            end

            -- property descriptions
            add_section_with_description(bufnr, "Property", properties)

            -- method descriptions
            add_section_with_description(bufnr, "Method", methods)

            -- set buffer readonly option
            vim.api.nvim_buf_set_option(bufnr, "readonly", true)
            vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

            -- user config function
            config.options.doc_keymaps.user_config(bufnr)

            -- quit buffer mapping
            for _, value in pairs(config.options.doc_keymaps.close) do
                vim.api.nvim_buf_set_keymap(
                    bufnr,
                    "n",
                    value,
                    "<Cmd>lua vim.api.nvim_win_close(" .. 0 .. ", true)<CR>",
                    { noremap = true, silent = true }
                )
            end
        else
            vim.notify("Native class not found.", vim.log.levels.ERROR)
        end
    end
    return bufnr
end

--- Create a documentation buffer for a symbol
---@param symbol string Symbol name
---@return integer Buffer handle
local function create_doc_buffer(symbol)
    local bufnr = get_buffer_for_name(symbol)
    if bufnr == -1 then
        -- create documentation using LSP server
        bufnr = add_content_to_buffer(symbol)
    end
    return bufnr
end

--- Open documentation window inside a new tab
---@param symbol string Symbol name
function M.open_doc_in_new_tab(symbol)
    local bufnr = create_doc_buffer(symbol)
    if bufnr ~= -1 then
        vim.cmd(":tab split")
        vim.api.nvim_win_set_buf(0, bufnr)
        set_win_conceal(0)
    end
end

--- Open documentation window inside a new tab with the word under cursor
function M.open_doc_on_cursor_in_new_tab()
    local wordUnderCursor = vim.fn.expand("<cword>")
    M.open_doc_in_new_tab(wordUnderCursor)
end

--- Open documentation window inside a new vsplit window
---@param symbol string Symbol name
---@param right boolean Open documentation on the left or right
function M.open_doc_in_vsplit_win(symbol, right)
    local bufnr = create_doc_buffer(symbol)
    if bufnr ~= -1 then
        vim.cmd(":vsplit")
        if right then
            vim.cmd(":wincmd l")
        end
        vim.api.nvim_win_set_buf(0, bufnr)
        set_win_conceal(0)
    end
end

--- Open documentation window inside a new vsplit window with the word under cursor
---@param right boolean Open documentation on the left or right
function M.open_doc_on_cursor_in_vsplit_win(right)
    local wordUnderCursor = vim.fn.expand("<cword>")
    M.open_doc_in_vsplit_win(wordUnderCursor, right)
end

--- Open documentation window inside a new split window
---@param symbol string Symbol name
---@param top boolean Open documentation on the bottom or top
function M.open_doc_in_split_win(symbol, top)
    local bufnr = create_doc_buffer(symbol)
    if bufnr ~= -1 then
        vim.cmd(":split")
        if top then
            vim.cmd(":wincmd k")
        end
        vim.api.nvim_win_set_buf(0, bufnr)
        set_win_conceal(0)
    end
end

--- Open documentation window inside a new split window with the word under cursor
---@param top boolean Open documentation on the bottom or top
function M.open_doc_on_cursor_in_split_win(top)
    local wordUnderCursor = vim.fn.expand("<cword>")
    M.open_doc_in_split_win(wordUnderCursor, top)
end

--- Open documentation window inside a new floating window
---@param symbol string Symbol name
function M.open_doc_in_floating_win(symbol)
    local bufnr = create_doc_buffer(symbol)
    if bufnr ~= -1 then
        if vim.api.nvim_win_get_config(0).relative == "" then
            -- current window isn't floating
            local win = vim.api.nvim_open_win(bufnr, true, utils.floating_window_opts())
            set_win_conceal(win)
        else
            vim.api.nvim_win_set_buf(0, bufnr)
        end
    end
end

--- Open documentation window inside a new floating window with the word under cursor
function M.open_doc_on_cursor_in_floating_win()
    local wordUnderCursor = vim.fn.expand("<cword>")
    M.open_doc_in_floating_win(wordUnderCursor)
end

--- Open documentation inside the current window
---@param symbol string Symbol name
function M.open_doc_in_current_win(symbol)
    local bufnr = create_doc_buffer(symbol)
    if bufnr ~= -1 then
        vim.api.nvim_win_set_buf(0, bufnr)
        set_win_conceal(0)
    end
end

--- Open documentation inside the current window with the word under cursor
function M.open_doc_on_cursor_in_current_win()
    local wordUnderCursor = vim.fn.expand("<cword>")
    M.open_doc_in_current_win(wordUnderCursor)
end

function M.setup(opts)
    -- user plugin config
    config.setup(opts)

    if config.options.lsp_setup then
        local host = "127.0.0.1"
        local port = os.getenv("GDScript_Port") or "6005"
        local cmd = { "nc", host, port }

        if vim.fn.has("win32") == 1 then
            cmd[1] = "ncat"
        else
            if vim.fn.has("nvim-0.8") == 1 then
                cmd = vim.lsp.rpc.connect(host, port)
            end
        end

        --LSP Setup
        require("lspconfig").gdscript.setup({
            on_attach = function(client, _)
                config.options.on_attach()
                if client_id == -1 then
                    client_id = client.id
                end
            end,
            cmd = cmd,
            handlers = {
                ["gdscript/capabilities"] = function(_, result, _)
                    -- add all the classes found
                    native_class_list = {}
                    for _, v in pairs(result.native_classes) do
                        table.insert(native_class_list, v.name)
                    end
                end,
            },
        })
    end
end

function M.get_capabilities_handler()
    return function(_, result, _)
        native_class_list = require("gdscript_extended").get_native_classes()
        for _, v in pairs(result.native_classes) do
            table.insert(native_class_list, v.name)
        end
    end
end

return M
