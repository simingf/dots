-- ========================================================================== --
-- ==                           EDITOR SETTINGS                            == --
-- ========================================================================== --

-- enable line numbers
vim.opt.number = true
vim.opt.relativenumber = true
-- keep sign column on
vim.opt.signcolumn = 'yes'
-- highlight current line
vim.opt.cursorline = true
-- minimal number of screen lines to keep above and below the cursor
vim.opt.scrolloff = 5
-- line wrapping
vim.opt.wrap = true
-- preserve indentation when line wrapping
vim.opt.breakindent = true
-- enable mouse for all modes
vim.opt.mouse = 'a'
-- include both lower and upper case for search
vim.opt.ignorecase = true
-- ignore upper case letters unless the search includes upper case letters
vim.opt.smartcase = true
-- disable highlighting the result of the most recent search all the time
vim.opt.hlsearch = false
-- set how many spaces a tab is
vim.opt.tabstop = 4
-- set how many spaces << and >> indent by
vim.opt.shiftwidth = 4
-- enable converting a tab into spaces
vim.opt.expandtab = true
-- disable showing current mode since lualine shows
vim.opt.showmode = false
-- enable hexademical colors instead of only 256 colors
vim.opt.termguicolors = true
-- configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true
-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- ========================================================================== --
-- ==                           KEY BINDINGS                               == --
-- ========================================================================== --

-- set the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
-- make j and k work with wrapped lines
-- vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true, silent = true })
-- bind H to ^ and L to $
vim.keymap.set('n', 'H', '^', { noremap = true, silent = true })
vim.keymap.set('n', 'L', '$', { noremap = true, silent = true })
-- shift up and down to move line
vim.keymap.set('n', '<S-Up>', 'ddkP', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Down>', 'ddp', { noremap = true, silent = true })
-- select all text in current buffer
vim.keymap.set('n', '<leader>a', ':keepjumps normal! ggVG<cr>')
-- yank and paste from clipboard
vim.keymap.set('v', 'gy', '"+y')
vim.keymap.set('n', 'gp', '"+p')
-- prevent x or X from modifying the internal register
vim.keymap.set({ 'n', 'x' }, 'x', '"_x')
vim.keymap.set({ 'n', 'x' }, 'X', '"_d')
-- set M to m for setting marks
-- set m to ` for jumping to marks
vim.keymap.set('n', 'M', 'm')
vim.keymap.set('n', 'm', '`')
-- swap windows
vim.api.nvim_set_keymap('n', '<Tab>', '<C-w>w', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>w', '<C-w>', { noremap = true, silent = true })
-- highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- ========================================================================== --
-- ==                           DIAGNOSTICS                                == --
-- ========================================================================== --

-- change diagnostic icons
local sign = function(opts)
    vim.fn.sign_define(opts.name, {
        texthl = opts.name,
        text = opts.text,
        numhl = ''
    })
end

sign({ name = 'DiagnosticSignError', text = '' })
sign({ name = 'DiagnosticSignWarn', text = '' })
sign({ name = 'DiagnosticSignHint', text = '' })
sign({ name = 'DiagnosticSignInfo', text = '' })

-- configure diagnostic options
vim.diagnostic.config({
    -- Show diagnostic message using virtual text.
    virtual_text = false,
    -- Show a sign next to the line with a diagnostic.
    signs = true,
    -- Update diagnostics while editing in insert mode.
    update_in_insert = false,
    -- Use an underline to show a diagnostic location.
    underline = true,
    -- Order diagnostics by severity.
    severity_sort = true,
    -- Show diagnostic messages in floating windows.
    float = {
        border = 'rounded',
        source = 'always',
    },
})

-- ========================================================================== --
-- ==                               PLUGINS                                == --
-- ========================================================================== --

-- setup code from documentation --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system(
        { "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", -- latest stable release
            lazypath })
end
vim.opt.rtp:prepend(lazypath)
-- setup code from documentation --

require("lazy").setup({
    -- dependencies
    { 'nvim-lua/plenary.nvim' },
    { 'kyazdani42/nvim-web-devicons' },
    { 'MunifTanjim/nui.nvim' },
    { 'tpope/vim-repeat' },

    -- theme
    {
        "catppuccin/nvim",
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",             -- latte, frappe, macchiato, mocha
                transparent_background = true, -- disables setting the background color.
                show_end_of_buffer = false,    -- shows the '~' characters after the end of buffers
                integrations = {
                    cmp = true,
                    gitsigns = false,
                    nvimtree = true,
                    treesitter = true,
                    notify = false,
                    mini = {
                        enabled = true,
                        indentscope_color = "",
                    },
                    -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
                },
            })
            vim.cmd.colorscheme "catppuccin"
        end
    },

    -- editor ui
    {
        'nvim-lualine/lualine.nvim',
        config = function()
            require('lualine').setup({
                options = {
                    theme = 'catppuccin',
                    icons_enabled = true,
                    section_separators = '',
                    component_separators = '|'
                },
            })
        end
    },
    {
        'lewis6991/gitsigns.nvim',
        config = true
    },
    {
        'folke/trouble.nvim',
        config = function()
            require('trouble').setup({})
            vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle() end)
            vim.keymap.set("n", "<leader>xw", function() require("trouble").toggle("workspace_diagnostics") end)
            vim.keymap.set("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end)
            vim.keymap.set("n", "<leader>xq", function() require("trouble").toggle("quickfix") end)
            vim.keymap.set("n", "<leader>xl", function() require("trouble").toggle("loclist") end)
            vim.keymap.set("n", "glr", function() require("trouble").toggle("lsp_references") end)
        end
    },
    {
        'akinsho/bufferline.nvim',
        config = function()
            require('bufferline').setup({
                options = {
                    -- one tab per file
                    mode = 'buffers',
                    offsets = {
                        { filetype = 'NvimTree' }
                    },
                },
                highlights = {
                    buffer_selected = {
                        italic = false
                    },
                    indicator_selected = {
                        fg = { attribute = 'fg', highlight = 'Function' },
                        italic = false
                    }
                }
            })
            vim.keymap.set('n', '<leader>h', ':bprev<cr>')
            vim.keymap.set('n', '<leader>l', ':bnext<cr>')
        end
    },
    {
        'echasnovski/mini.bufremove',
        config = function()
            require('mini.bufremove').setup({})
            vim.keymap.set('n', '<leader>cc', '<cmd>lua pcall(MiniBufremove.delete)<cr>')
        end
    },
    {
        'echasnovski/mini.cursorword',
        config = true
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            require('ibl').setup({
                enabled = true,
                scope = {
                    enabled = true
                },
                indent = {
                    char = '▏'
                }
            })
        end
    },
    {
        "folke/todo-comments.nvim"
    },

    -- editor utilities
    {
        'nvim-treesitter/nvim-treesitter',
        config = function()
            require("nvim-treesitter.install").prefer_git = true
            require('nvim-treesitter.configs').setup({
                highlight = {
                    enable = true,
                },
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ['af'] = '@function.outer',
                            ['if'] = '@function.inner',
                            ['ac'] = '@class.outer',
                            ['ic'] = '@class.inner',
                            ['as'] = { query = '@scope', query_group = 'locals' },
                        }
                    },
                },
                ensure_installed = {
                    'lua', 'bash', 'python', 'go', 'javascript', 'typescript',
                },
            })
        end
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects'
    },
    {
        'ggandor/leap.nvim',
        config = function()
            require('leap').create_default_mappings()
            require('leap').opts.special_keys.prev_target = '<bs>'
            require('leap').opts.special_keys.prev_group = '<bs>'
            require('leap.user').set_repeat_keys('<cr>', '<bs>')
        end
    },
    {
        'numToStr/Comment.nvim',
        config = true
    },
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = true
    },
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    {
        'nvim-telescope/telescope.nvim',
        config = function()
            -- fzf for a pattern in the current file
            vim.keymap.set('n', '<leader><space>', '<cmd>Telescope current_buffer_fuzzy_find<cr>')
            -- grep for a pattern in current directory
            vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
            -- search open files
            vim.keymap.set('n', '<leader>fo', '<cmd>Telescope buffers<cr>')
            -- search files in current directory
            vim.keymap.set('n', '<leader>fd', '<cmd>Telescope find_files<cr>')
            -- search recently opened files
            vim.keymap.set('n', '<leader>fr', '<cmd>Telescope oldfiles<cr>')
            -- search diagnostic messages
            vim.keymap.set('n', '<leader>fdd', '<cmd>Telescope diagnostics<cr>')
            -- search in clipboard
            vim.keymap.set('n', '<leader>fy', '<cmd>Telescope neoclip<cr>')
            -- search notifications
            vim.keymap.set('n', '<leader>fn', '<cmd>Telescope notify<cr>')
        end
    },
    {
        'AckslD/nvim-neoclip.lua',
        config = true
    },

    -- file system
    {
        'kyazdani42/nvim-tree.lua',
        config = function()
            require('nvim-tree').setup({
                view = {
                    width = 25,
                },
                hijack_cursor = false,
                on_attach = function(bufnr)
                    local bufmap = function(lhs, rhs, desc)
                        vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
                    end

                    -- See :help nvim-tree.api
                    local api = require('nvim-tree.api')
                    bufmap('<cr>', api.node.open.edit, 'Expand folder or go to file')
                    bufmap('cd', api.tree.change_root_to_node, 'Set current directory as root')
                    bufmap('..', api.node.navigate.parent, 'Move to parent directory')
                    bufmap('hh', api.tree.toggle_hidden_filter, 'Toggle hidden files')
                end
            })
            vim.cmd [[hi NvimTreeNormal guibg=NONE ctermbg=NONE]]
            vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeToggle<cr>')
        end
    },

    -- mason
    {
        'williamboman/mason.nvim',
        config = true
    },
    {
        'williamboman/mason-lspconfig.nvim',
        config = function()
            require('mason-lspconfig').setup({
                ensure_installed = {
                    "lua_ls", "pylsp", "eslint"
                }
            })
            require("mason-lspconfig").setup_handlers {
                function(server_name) -- default handler (optional)
                    require("lspconfig")[server_name].setup {
                        capabilities = require('cmp_nvim_lsp').default_capabilities()
                    }
                end,
            }
        end
    },

    -- lsp
    {
        'neovim/nvim-lspconfig',
        config = function()
            vim.api.nvim_create_autocmd('LspAttach', {
                desc = 'LSP actions',
                callback = function()
                    local bufmap = function(mode, lhs, rhs)
                        local opts = { buffer = true }
                        vim.keymap.set(mode, lhs, rhs, opts)
                    end

                    -- Displays hover information about the symbol under the cursor
                    bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')

                    -- Jump to the definition
                    bufmap('n', 'gdef', '<cmd>lua vim.lsp.buf.definition()<cr>')

                    -- Jump to declaration
                    bufmap('n', 'gdec', '<cmd>lua vim.lsp.buf.declaration()<cr>')

                    -- Jumps to the definition of the type symbol
                    bufmap('n', 'gtd', '<cmd>lua vim.lsp.buf.type_definition()<cr>')

                    -- Lists all the implementations for the symbol under the cursor
                    bufmap('n', 'gimp', '<cmd>lua vim.lsp.buf.implementation()<cr>')

                    -- Lists all the references
                    bufmap('n', 'gref', '<cmd>lua vim.lsp.buf.references()<cr>')

                    -- Displays a function's signature information
                    bufmap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')

                    -- Renames all references to the symbol under the cursor
                    bufmap('n', 'grn', '<cmd>lua vim.lsp.buf.rename()<cr>')

                    -- Selects a code action available at the current cursor position
                    bufmap({ 'n', 'v' }, 'gca', '<cmd>lua vim.lsp.buf.code_action()<cr>')

                    -- Show diagnostics in a floating window
                    bufmap('n', 'gdd', '<cmd>lua vim.diagnostic.open_float()<cr>')

                    -- Move to the previous diagnostic
                    bufmap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')

                    -- Move to the next diagnostic
                    bufmap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')
                end
            })
        end
    },

    -- formatter
    {
        'stevearc/conform.nvim',
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    python = { "isort", "black" },
                    javascript = { "prettierd" },
                    typescript = { "prettierd" },
                    javascriptreact = { "prettierd" },
                    typescriptreact = { "prettierd" },
                    css = { "prettierd" },
                    json = { "prettierd" },
                    markdown = { "prettierd" },
                },
                format_on_save = {
                    lsp_fallback = true,
                    timeout_ms = 500,
                },
            })
        end
    },

    -- cmp (autocompletion)
    {
        'hrsh7th/nvim-cmp',
        config = function()
            vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
            local cmp = require('cmp')
            local luasnip = require('luasnip')
            local has_words_before = function()
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and
                    vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end
            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end
                },
                sources = {
                    -- { name = 'copilot',  keyword_length = 1 },
                    { name = 'luasnip',  keyword_length = 1 },
                    { name = 'nvim_lsp', keyword_length = 1 },
                    { name = 'buffer',   keyword_length = 2 },
                    { name = 'path',     keyword_length = 3 },
                },
                window = {
                    documentation = cmp.config.window.bordered()
                },
                formatting = {
                    fields = { 'menu', 'abbr', 'kind' },
                    format = function(entry, item)
                        local menu_icon = {
                            -- copilot = 'GPT',
                            nvim_lsp = 'LSP',
                            luasnip = 'SNIP',
                            buffer = 'BUF',
                            path = 'PATH',
                        }
                        item.menu = menu_icon[entry.source.name]
                        return item
                    end,
                },
                mapping = {
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.abort(),
                    ['<C-y>'] = cmp.config.diable, --disable default functionality
                    ['<CR>'] = cmp.mapping.confirm({ select = false }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }
            })
        end
    },
    {
        'hrsh7th/cmp-cmdline',
        config = function()
            local cmp = require('cmp')
            -- `/` cmdline setup.
            cmp.setup.cmdline('/', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'buffer' }
                }
            })
            -- `:` cmdline setup.
            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = 'path' }
                }, {
                    {
                        name = 'cmdline',
                        option = {
                            ignore_cmds = { 'Man', '!' }
                        }
                    }
                })
            })
        end
    },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },

    -- snippets
    {
        'L3MON4D3/LuaSnip',
        config = true
    },
    { 'saadparwaiz1/cmp_luasnip' },
    {
        'rafamadriz/friendly-snippets',
        config = function()
            require('luasnip.loaders.from_vscode').lazy_load()
        end
    },

    -- copilot
    -- {
    --     'zbirenbaum/copilot.lua',
    --     config = function()
    --         require("copilot").setup({
    --             suggestion = { enabled = false },
    --             panel = { enabled = false },
    --         })
    --     end
    -- },
    -- {
    --     'zbirenbaum/copilot-cmp',
    --     config = true
    -- },
})

-- ========================================================================== --
-- ==                           MISC SETTINGS                              == --
-- ========================================================================== --

-- lua lsp setup to fix undefined global vim error
require('lspconfig').lua_ls.setup({
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' }
            }
        }
    }
})

require("lspconfig").clangd.setup {
    cmd = {
        "clangd",
        "--offset-encoding=utf-16",
    },
}

-- custom python provider
local function isempty(s)
    return s == nil or s == ""
end
local function use_if_defined(val, fallback)
    return val ~= nil and val or fallback
end
local conda_prefix = os.getenv("CONDA_PREFIX")
if not isempty(conda_prefix) then
    vim.g.python_host_prog = use_if_defined(vim.g.python_host_prog, conda_prefix .. "/bin/python")
    vim.g.python3_host_prog = use_if_defined(vim.g.python3_host_prog, conda_prefix .. "/bin/python")
else
    vim.g.python_host_prog = use_if_defined(vim.g.python_host_prog, "python")
    vim.g.python3_host_prog = use_if_defined(vim.g.python3_host_prog, "python3")
end
