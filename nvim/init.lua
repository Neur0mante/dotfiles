vim.g.mapleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.termguicolors = true
opt.completeopt = "menu,menuone,noselect"

require("config.lazy")

vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", {})
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", {})
vim.keymap.set("n", "<leader>fz", "<cmd>lua require('fzf-lua').files()<CR>", {})

vim.keymap.set("n", "<leader>fzf", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fzg", fzf.live_grep, { desc = "Live grep" })
