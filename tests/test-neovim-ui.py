"""Smoke-test a built Home Manager generation without activating it.

Usage: python3 tests/test-neovim-ui.py /nix/store/…-home-manager-generation
"""

import os
from pathlib import Path
import subprocess
import sys
import tempfile


generation = Path(sys.argv[1])
files = generation / "home-files"
init = files / ".config/nvim/init.lua"
pack = Path(os.readlink(files / ".local/share/nvim/site/pack/hm")).parents[1]
nvim = generation / "home-path/bin/nvim"

checks = r"""
assert(vim.g.colors_name == "carbonfox")
for _, name in ipairs({
  "ibl", "gitsigns", "mini.icons", "mini.cursorword",
  "mini.statusline", "mini.tabline", "mini.notify", "mini.completion", "mini.indentscope",
}) do
  assert(package.loaded[name], name .. " was not loaded")
end
assert(vim.o.shiftwidth == 2 and vim.o.tabstop == 2)
assert(vim.o.clipboard == "" and vim.o.mouse == "nvi")
assert(vim.o.updatetime == 4000 and vim.o.redrawtime == 10000)
assert(vim.diagnostic.config().virtual_text == false)
assert(#vim.api.nvim_get_autocmds({ event = "LspAttach" }) > 0)
vim.cmd.colorscheme("carbonfox")
local visual = vim.api.nvim_get_hl(0, { name = "Visual" })
assert(visual.bg == 0x454545)
assert(MiniIndentscope.config.symbol == "╎")
assert(require("ibl.config").get_config(0).indent.char == "│")
assert(require("ibl.config").get_config(0).scope.enabled == false)
local predicate = MiniIndentscope.config.draw.predicate
assert(predicate({ body = { is_incomplete = false } }))
assert(not predicate({ body = { is_incomplete = true } }))
assert(vim.api.nvim_get_hl(0, { name = "RainbowRed" }).fg == 0xE06C75)
vim.cmd.edit("files/nvim/init.lua")
vim.wait(300)
assert(vim.b.ts_started)
MiniIndentscope.draw()
vim.wait(300)
MiniIndentscope.undraw()
require("ibl").refresh(0)
MiniFiles.open()
MiniFiles.close()
"""

with tempfile.TemporaryDirectory(prefix="nvim-ui-", dir="/tmp/opencode") as tmp:
    env = os.environ.copy()
    env.pop("NVIM_MINIMAL", None)
    for kind in ("CONFIG", "DATA", "STATE", "CACHE"):
        env[f"XDG_{kind}_HOME"] = f"{tmp}/{kind.lower()}"
    script = Path(tmp) / "checks.lua"
    script.write_text(
        "local ok, err = pcall(function()\n"
        + checks
        + '\nend)\nif not ok then print(err); vim.cmd("cquit") end\n'
    )
    command = [
        str(nvim), "--headless", "-i", "NONE",
        "--cmd", f'let &packpath = "{pack}," . $VIMRUNTIME',
        "-u", str(init),
    ]
    subprocess.run(command + [f"+luafile {script}", "+qa"], env=env, check=True, timeout=30)
    env["NVIM_MINIMAL"] = "1"
    subprocess.run(
        command + [
            '+lua if vim.g.colors_name == "carbonfox" or vim.o.termguicolors or _G.MiniCompletion then vim.cmd("cquit") end',
            "+qa",
        ],
        env=env, check=True, timeout=30,
    )
print("Neovim UI and minimal-mode checks passed")
