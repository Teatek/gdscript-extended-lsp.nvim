local config = require("gdscript_extended.config")

local U = {}

function U.sort_table_by_name(table)
    -- TODO
    return table
end

function U.convert_to_h1(str)
    return "# " .. str
end

function U.floating_window_opts()
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- calculate our floating window size
    local win_height = math.ceil(height * config.options.floating_win_size - 4)
    local win_width  = math.ceil(width * config.options.floating_win_size)
    -- and its starting position
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    return {
        relative = "editor",
        width = win_width,
        height = win_height,
        col = col,
        row = row,
        border = config.options.floating_border_style,
        style = "minimal"
    }
end

return U
