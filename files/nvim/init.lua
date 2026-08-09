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

local bat_like_palette = {
  bg = "#1e1e1e",
  fg = "#c8c8c8",
  comment = "#6c7a89",
  keyword = "#ff5f87",
  string = "#ffd75f",
  function_name = "#5fd7ff",
  type = "#87d7ff",
  constant = "#ffaf5f",
  number = "#d7af87",
  operator = "#d7af5f",
  special = "#5fd7af",
  identifier = "#f8f8f2",
}

local function apply_bat_like_highlights()
  local hl = vim.api.nvim_set_hl
  hl(0, "Normal", { fg = bat_like_palette.fg, bg = bat_like_palette.bg })
  hl(0, "NormalFloat", { fg = bat_like_palette.fg, bg = bat_like_palette.bg })
  hl(0, "Comment", { fg = bat_like_palette.comment, italic = true })
  hl(0, "String", { fg = bat_like_palette.string })
  hl(0, "Character", { link = "String" })
  hl(0, "Number", { fg = bat_like_palette.number })
  hl(0, "Float", { link = "Number" })
  hl(0, "Boolean", { fg = bat_like_palette.constant, bold = true })
  hl(0, "Constant", { fg = bat_like_palette.constant })
  hl(0, "Identifier", { fg = bat_like_palette.identifier })
  hl(0, "Function", { fg = bat_like_palette.function_name })
  hl(0, "Statement", { fg = bat_like_palette.keyword, bold = true })
  hl(0, "Keyword", { fg = bat_like_palette.keyword, bold = true })
  hl(0, "Operator", { fg = bat_like_palette.operator })
  hl(0, "Type", { fg = bat_like_palette.type })
  hl(0, "Special", { fg = bat_like_palette.special })
  hl(0, "PreProc", { fg = bat_like_palette.keyword })
  hl(0, "Underlined", { undercurl = true })
  hl(0, "CursorLine", { bg = "#262626" })
  hl(0, "Visual", { bg = "#353535" })

  local treesitter_links = {
    ["@comment"] = "Comment",
    ["@string"] = "String",
    ["@string.escape"] = "Special",
    ["@character"] = "Character",
    ["@number"] = "Number",
    ["@boolean"] = "Boolean",
    ["@constant"] = "Constant",
    ["@constant.builtin"] = "Constant",
    ["@function.builtin"] = "Function",
    ["@function"] = "Function",
    ["@function.call"] = "Function",
    ["@method"] = "Function",
    ["@method.call"] = "Function",
    ["@keyword"] = "Keyword",
    ["@keyword.return"] = "Keyword",
    ["@keyword.function"] = "Keyword",
    ["@keyword.operator"] = "Keyword",
    ["@keyword.import"] = "Keyword",
    ["@keyword.directive"] = "Keyword",
    ["@keyword.modifier"] = "Keyword",
    ["@keyword.conditional"] = "Keyword",
    ["@keyword.repeat"] = "Keyword",
    ["@keyword.exception"] = "Keyword",
    ["@type"] = "Type",
    ["@type.builtin"] = "Type",
    ["@module"] = "Type",
    ["@namespace"] = "Type",
    ["@attribute"] = "Special",
    ["@tag"] = "Special",
    ["@variable.member"] = "Identifier",
    ["@variable"] = "Identifier",
    ["@variable.builtin"] = "Identifier",
    ["@variable.parameter"] = "Identifier",
    ["@variable.parameter.builtin"] = "Identifier",
    ["@property"] = "Identifier",
    ["@field"] = "Identifier",
    ["@parameter"] = "Identifier",
    ["@operator"] = "Operator",
    ["@punctuation.delimiter"] = "Identifier",
    ["@punctuation.bracket"] = "Identifier",
    ["@punctuation.special"] = "Special",
    ["@label"] = "Special",
    ["@text.title"] = "Keyword",
    ["@text.strong"] = "Keyword",
    ["@text.emphasis"] = "Keyword",
    ["@text.literal"] = "String",
    ["@text.reference"] = "Special",
  }

  for group, target in pairs(treesitter_links) do
    hl(0, group, { link = target })
  end
end

if not minimal_mode then
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = apply_bat_like_highlights,
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

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not minimal_mode and not vim.loop.fs_stat(lazypath) then
  local lazy_repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazy_repo,
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
if not minimal_mode then
  vim.opt.rtp:prepend(lazypath)

  require("lazy").setup({
    {
      "loctvl842/monokai-pro.nvim",
      priority = 1000,
      config = function()
        require("monokai-pro").setup({
          filter = "classic",
        })
        vim.cmd.colorscheme("monokai-pro")
        apply_bat_like_highlights()
      end,
    },
    {
      "echasnovski/mini.nvim",
      version = false,
      config = function()
        require("mini.ai").setup()
        require("mini.comment").setup()
        require("mini.files").setup()
        require("mini.pairs").setup()
        require("mini.surround").setup()
        require("mini.statusline").setup()
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
      end,
    },
    {
      "HiPhish/rainbow-delimiters.nvim",
      dependencies = { "nvim-treesitter/nvim-treesitter" },
      event = "VeryLazy",
      config = function()
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
      end,
    },
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter").setup({
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
          install_dir = vim.fn.stdpath("data") .. "/site",
        })

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
      end,
    },
  }, {
    change_detection = { notify = false },
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
