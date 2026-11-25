vim.g.mapleader = " "
vim.g.maplocalleader = " "

local minimal_mode = vim.env.NVIM_MINIMAL == "1"

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = "nvi"
vim.opt.clipboard = ""
vim.opt.breakindent = false
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "auto"
vim.opt.updatetime = 4000
vim.opt.timeoutlen = 1000
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = false
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "nosplit"
vim.opt.cursorline = false
vim.opt.cursorlineopt = "number"
vim.opt.scrolloff = 0
vim.opt.confirm = false
vim.opt.termguicolors = true
vim.opt.lazyredraw = true
vim.opt.redrawtime = 10000
vim.opt.synmaxcol = 5000
vim.opt.pumblend = 0
vim.opt.winblend = 0
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")

if minimal_mode then
  vim.opt.termguicolors = false
  vim.opt.undofile = false
  vim.opt.ignorecase = false
  vim.opt.smartcase = false
  vim.opt.splitright = false
  vim.opt.splitbelow = false
end

local function apply_ui_highlights()
  vim.api.nvim_set_hl(0, "Visual", {
    fg = "#000000",
    bg = "#FFFF00",
    ctermfg = "black",
    ctermbg = "yellow",
  })
end

if not minimal_mode then
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = apply_ui_highlights,
  })
end

vim.keymap.set("i", "kk", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("i", "<S-CR>", "<Esc>o", { desc = "Open new line below" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", ";", ":")
vim.keymap.set("n", ":", ";")
vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
vim.keymap.set("n", "<leader>e", "<cmd>lua MiniFiles.open()<CR>", { desc = "File explorer" })

-- Plugins and Tree-sitter parsers are supplied by home/modules/neovim.nix.
-- Startup never clones plugins or compiles parsers into the home directory.
if not minimal_mode then
  vim.opt.background = "dark"
  vim.opt.signcolumn = "yes"
  vim.opt.laststatus = 2
  vim.cmd.colorscheme("carbonfox")
  apply_ui_highlights()

  require("mini.icons").setup()
  require("mini.icons").mock_nvim_web_devicons()
  require("mini.ai").setup()
  require("mini.comment").setup()
  require("mini.cursorword").setup()
  require("mini.files").setup()
  require("mini.pairs").setup()
  require("mini.surround").setup()
  require("mini.statusline").setup()
  require("mini.tabline").setup()
  require("mini.notify").setup()
  -- One Git gutter and one scope renderer: avoid gitsigns/mini.diff and
  -- ibl/mini.indentscope drawing over each other.
  require("gitsigns").setup()

  local indent_highlights = {
    "RainbowRed", "RainbowYellow", "RainbowBlue", "RainbowOrange",
    "RainbowGreen", "RainbowViolet", "RainbowCyan",
  }
  local indent_colors = {
    "#E06C75", "#E5C07B", "#61AFEF", "#D19A66",
    "#98C379", "#C678DD", "#56B6C2",
  }
  local hooks = require("ibl.hooks")
  hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    for index, group in ipairs(indent_highlights) do
      vim.api.nvim_set_hl(0, group, { fg = indent_colors[index] })
    end
  end)
  require("ibl").setup({
    indent = { char = "|", highlight = indent_highlights },
    scope = { highlight = { "RainbowRed", "RainbowYellow" } },
    -- Preserve the existing large-buffer precaution for visual decorations.
    exclude = {
      buftypes = { "terminal", "nofile", "quickfix", "prompt" },
    },
  })
  hooks.register(hooks.type.ACTIVE, function(bufnr)
    local lines = vim.api.nvim_buf_line_count(bufnr)
    return lines < 1000 and vim.api.nvim_buf_get_offset(bufnr, lines) < 100000
  end)
  require("mini.completion").setup({
    delay = { completion = 120, info = 100, signature = 50 },
    lsp_completion = { source_func = "omnifunc", auto_setup = true },
  })

  local imap_expr = function(lhs, rhs)
    vim.keymap.set("i", lhs, rhs, { expr = true, replace_keycodes = false })
  end

  imap_expr("<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]])
  imap_expr("<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]])

  _G.cr_action = function()
    if vim.fn.complete_info()["selected"] ~= -1 then
      return "\25"
    end
    return "\r"
  end
  vim.keymap.set("i", "<CR>", "v:lua.cr_action()", { expr = true })

  vim.g.rainbow_delimiters = {
    strategy = {
      [""] = "rainbow-delimiters.strategy.global",
    },
    query = {
      [""] = "rainbow-delimiters",
    },
    highlight = {
      "RainbowDelimiterRed",
      "RainbowDelimiterYellow",
      "RainbowDelimiterBlue",
      "RainbowDelimiterOrange",
      "RainbowDelimiterGreen",
      "RainbowDelimiterViolet",
      "RainbowDelimiterCyan",
    },
    condition = function(bufnr)
      return vim.api.nvim_buf_line_count(bufnr) < 1000
        and vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr)) < 100000
    end,
  }

  require("nvim-treesitter").setup({})

  vim.api.nvim_create_autocmd("FileType", {
    callback = function()
      if vim.b.ts_started then
        return
      end
      local ft = vim.bo.filetype
      local lang = ft ~= "" and vim.treesitter.language.get_lang(ft) or nil
      if lang and pcall(vim.treesitter.language.inspect, lang) then
        vim.b.ts_started = true
        vim.treesitter.start()
      end
    end,
  })
end

vim.diagnostic.config({
  virtual_text = false,
  severity_sort = true,
  float = { border = "rounded" },
  underline = true,
  signs = true,
})

if not minimal_mode then
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local opts = { buffer = args.buf }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end,
  })
end

local servers = {
  "bashls",
  "clangd",
  "gopls",
  "lua_ls",
  "pyright",
  "rust_analyzer",
  "ts_ls",
}

if not minimal_mode then
  for _, server in ipairs(servers) do
    if vim.fn.executable(server) == 1 then
      vim.lsp.enable(server)
    end
  end
end
