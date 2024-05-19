# gdscript-extended-lsp.nvim

Add viewing documentation support for Godot using LSP.

Note: This plugin is still a WIP.

[gdscript-extended-lsp-demo.webm](https://github.com/Teatek/gdscript-extended-lsp.nvim/assets/38403802/0fb814b9-b28d-4399-bcff-81270aa6a36d)

## Installation

For a good documentation viewing experience, it's recommended to have TreeSitter installed with markdown and markdown_inline parsers.

```lua

-- lazy.nvim
{
  "Teatek/gdscript-extended-lsp.nvim"
}
```

**Important** : For windows, ncat need to be installed. Without it, neovim wont be able to attach to the LSP server.

## Setup

Example setup (replace already LSP setup for godot):

```lua
-- Function for buffers attached to lsp server
local on_attach = function()

  -- (Optional) User command with autocompletion
  if vim.fn.exists(':GodotDoc') == 0 then
    vim.api.nvim_create_user_command("GodotDoc", function(cmd)
      -- Change the function depending on your preferences
      require('gdscript_extended').open_doc_in_vsplit_win(cmd.args, true)
    end,{
    nargs = 1,
    complete = function()
      return require('gdscript_extended').get_native_classes()
    end
    })
  end

  -- keymaps
  vim.keymap.set("n", "K", vim.lsp.buf.hover, {buffer=0})
  vim.keymap.set("n", "gD", "<Cmd>lua require('gdscript_extended').open_doc_on_cursor_in_vsplit_win(true)<CR>", {buffer=0})
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, {buffer=0})
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, {buffer=0})
  vim.keymap.set("n", "<leader>D", "<Cmd>Telescope gdscript_extended vsplit<CR>", {buffer=0})
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {buffer=0})
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {buffer=0})
  vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, {buffer=0})
end

-- Function for documentation buffers
local doc_conf = function(bufnr)
  -- /!\ Don't forget to give the buffer handle to your keymaps, etc /!\
  vim.keymap.set("n", "gD", "<Cmd>lua require('gdscript_extended').open_doc_on_cursor_in_vsplit_win(true)<CR>", {buffer=bufnr})
  vim.keymap.set("n", "<leader>D", "<Cmd>Telescope gdscript_extended vsplit<CR>", {buffer=bufnr})
end

-- Setup with values we changed
require('gdscript_extended').setup({
  on_attach = on_attach,
  doc_keymaps = {
    user_config = doc_conf
  },
})
```

Example setup without replace LSP setup for godot (useful for astronvim, lazyvim, etc):

```lua
-- Function for buffers attached to lsp server
local on_attach = function()

  -- (Optional) User command with autocompletion
  if vim.fn.exists(':GodotDoc') == 0 then
    vim.api.nvim_create_user_command("GodotDoc", function(cmd)
      -- Change the function depending on your preferences
      require('gdscript_extended').open_doc_in_vsplit_win(cmd.args, true)
    end,{
    nargs = 1,
    complete = function()
      return require('gdscript_extended').get_native_classes()
    end
    })
  end

  -- keymaps
  vim.keymap.set("n", "K", vim.lsp.buf.hover, {buffer=0})
  vim.keymap.set("n", "gD", "<Cmd>lua require('gdscript_extended').open_doc_on_cursor_in_vsplit_win(true)<CR>", {buffer=0})
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, {buffer=0})
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, {buffer=0})
  vim.keymap.set("n", "<leader>D", "<Cmd>Telescope gdscript_extended vsplit<CR>", {buffer=0})
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {buffer=0})
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {buffer=0})
  vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, {buffer=0})
end

-- Function for documentation buffers
local doc_conf = function(bufnr)
  -- /!\ Don't forget to give the buffer handle to your keymaps, etc /!\
  vim.keymap.set("n", "gD", "<Cmd>lua require('gdscript_extended').open_doc_on_cursor_in_vsplit_win(true)<CR>", {buffer=bufnr})
  vim.keymap.set("n", "<leader>D", "<Cmd>Telescope gdscript_extended vsplit<CR>", {buffer=bufnr})
end

-- Setup with values we changed
require("gdscript_extended").setup({
  on_attach = on_attach,
  doc_keymaps = {
    user_config = doc_conf,
  },
  -- Disable auto lsp setup
  lsp_setup = false,
})

-- Your custom lsp setup, only thing important is add a new handler
require("lspconfig").gdscript.setup({
  cmd = { "nc", "localhost", "6005" },
  on_attach = function(client, bufnr) vim.api.nvim_command('echo serverstart("' .. pipe .. '")') end,
  handlers = {
    -- This makes the magic happens
    ["gdscript/capabilities"] = require("gdscript_extended").get_capabilities_handler(),
  },
})


```

## Configuration

```lua
{
  on_attach = function() -- Function to execute when new buffer gets attached to lsp
  end,
  doc_file_extension = ".doc", -- Documentation file extension (can for example allow a better search in buffers list with telescope)
  doc_keymaps = {
  close = {"q", "<Esc>"}, -- Keymaps for closing documentation window
    user_config = function(bufnr) -- Attach function for the documentation buffer
    end,
  },
  floating_win_size = 0.8, -- Border style for floating windows
  floating_border_style = "none", -- Border style for floating windows (can be a string or an array: "none", "single", "double", "solid", "shadow")
  lsp_setup = true, -- If false the extension will not call the lsp setup. Useful for super-nvims (astronvim, lazyvim, etc...) or if you wanna do the setup for yourself with extra things
}
```

## Usage

Exposed function you can use in your keybindings:

```lua
require('gdscript_extended').open_doc_in_current_win(symbol_name)
-- second param is for the direction of the window (false is bottom, true is top)
require('gdscript_extended').open_doc_in_split_win(symbol_name, top)
-- second param is for the direction of the window (false is left, true is right)
require('gdscript_extended').open_doc_in_vsplit_win(symbol_name, right)
require('gdscript_extended').open_doc_in_floating_win(symbol_name)
require('gdscript_extended').open_doc_in_new_tab(symbol_name)

-- Same without giving symbol name in function param (use word under the cursor)

require('gdscript_extended').open_doc_on_cursor_in_current_win()
require('gdscript_extended').open_doc_on_cursor_in_split_win(top)
require('gdscript_extended').open_doc_on_cursor_in_vsplit_win(right)
require('gdscript_extended').open_doc_on_cursor_in_floating_win()
require('gdscript_extended').open_doc_on_cursor_in_new_tab()

```

## Telescope

```lua
require('telescope').load_extension('gdscript_extended')
```

`:Telescope gdscript_extended default` : Open in current window

`:Telescope gdscript_extended split` : Open in a split (to the top)

`:Telescope gdscript_extended vsplit` : Open in a vsplit (to the right)

`:Telescope gdscript_extended floating` : Open in a floating window

`:Telescope gdscript_extended tab` : Open in a new tab

Mapping for the default action `:Telescope gdscript_extended default` :

| Key     | Action   |
| ------- | -------- |
| `<CR>`  | current  |
| `<C-x>` | split    |
| `<C-v>` | vsplit   |
| `<C-f>` | floating |
| `<C-t>` | tab      |

## License

[MIT](./LICENSE)
