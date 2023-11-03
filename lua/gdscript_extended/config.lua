local M = {}

M.defaults = {
    on_attach = function()
    end,
    doc_file_extension = ".doc",
    doc_keymaps = {
        close = {"q", "<Esc>"},
        user_config = function(bufnr)
        end,
    },
    floating_win_size = 0.8,
    floating_border_style = "none",
}

M.options = {}

function M.setup(options)
    M.options = vim.tbl_deep_extend('force', {}, M.defaults, options or {})
end

return M
