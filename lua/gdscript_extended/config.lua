local M = {}

M.defaults = {
    on_attach = nil,
    doc_file_extension = ".doc",
    keymaps = {
        close = {"q", "<Esc>"},
        cursor = "gD",
    },
    win_style = 0,
    floating_border_style = "rounded",
    floating_win_size = 0.8,
}

M.options = {}

function M.setup(options)
    M.options = vim.tbl_deep_extend('force', {}, M.defaults, options or {})
end

return M
