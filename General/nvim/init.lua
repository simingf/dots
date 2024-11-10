-- ========================================================================== --
-- ==                           EDITOR SETTINGS                            == --
-- ========================================================================== --

-- enable line numbers
vim.opt.number = true
vim.opt.relativenumber = true
-- keep sign column on
vim.opt.signcolumn = 'yes'
-- highlight current line
vim.opt.cursorline = false
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
-- diagnostic icons
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
-- diagnostic config
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
-- ==                           KEY BINDINGS                               == --
-- ========================================================================== --

-- set the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
-- make j and k work with wrapped lines
vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true, silent = true })
-- bind H to ^ and L to $
vim.keymap.set({ 'n', 'x' }, 'H', '^', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'L', '$', { noremap = true, silent = true })
-- switch buffers
vim.keymap.set('n', '<leader>h', ':bprev<cr>')
vim.keymap.set('n', '<leader>l', ':bnext<cr>')
-- shift up and down to move line
vim.keymap.set('n', '<S-Up>', 'ddkP', { noremap = true, silent = true })
vim.keymap.set('n', '<S-Down>', 'ddp', { noremap = true, silent = true })
-- yank and paste from clipboard
vim.keymap.set({ 'n', 'x' }, 'gy', '"+y')
vim.keymap.set('n', 'gp', '"+p')
-- prevent x or X from modifying the internal register
vim.keymap.set({ 'n', 'x' }, 'x', '"_x')
vim.keymap.set({ 'n', 'x' }, 'X', '"_d')
-- swap windows
vim.api.nvim_set_keymap('n', '<Tab>', '<C-w>w', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>g', '<C-w>', { noremap = true, silent = true })
-- highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})
-- ctrl u / d centers afterwards
local function lazy(keys)
    keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
    return function()
        local old = vim.o.lazyredraw
        vim.o.lazyredraw = true
        vim.api.nvim_feedkeys(keys, 'nx', false)
        vim.o.lazyredraw = old
    end
end
vim.keymap.set('n', '<c-u>', lazy('<c-u>zz'), { desc = 'Scroll up half screen' })
vim.keymap.set('n', '<c-d>', lazy('<c-d>zz'), { desc = 'Scroll down half screen' })

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

    -- which key
    {
        "folke/which-key.nvim",
        opts = {},
        keys = {
            {
                "<leader><leader>",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },
    },

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

    -- noice: improved UI
    {
        "folke/noice.nvim",
        opts = {},
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
        config = function()
            require("noice").setup({
                lsp = {
                    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                        ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
                    },
                },
                -- you can enable a preset for easier configuration
                presets = {
                    bottom_search = true,         -- use a classic bottom cmdline for search
                    command_palette = true,       -- position the cmdline and popupmenu together
                    long_message_to_split = true, -- long messages will be sent to a split
                    inc_rename = false,           -- enables an input dialog for inc-rename.nvim
                    lsp_doc_border = false,       -- add a border to hover docs and signature help
                },
            })
        end
    },

    -- notifications
    {
        'rcarriga/nvim-notify',
        config = function()
            require('notify').setup({
                background_colour = "#000000",
                render = "wrapped-compact",
                minimum_width = 50,
                max_width = 100,
                stages = "fade_in_slide_out",
                timeout = 0,
            })
        end
    },

    -- status line at bottom
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

    -- git indicators on the left
    {
        'lewis6991/gitsigns.nvim',
        config = true
    },

    -- indentation indicators on the left
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

    -- highlight TODOs
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            keywords = {
                FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                TODO = { icon = " ", color = "info", alt = { "NYI" } },
                HINT = { icon = " ", color = "hint", alt = { "INFO", "NOTE" } },
                TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASS", "PASSED", "FAIL", "FAILED" } },
            },
        }
    },

    -- highlight all occurences of a word
    {
        'echasnovski/mini.cursorword',
        config = true
    },

    -- comments! normal: gcc, gbc. visual: gc, gb.
    {
        'numToStr/Comment.nvim',
        config = true
    },

    -- automatic closing brackets
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = true
    },

    -- leap: easy file navigation with 's'
    {
        'ggandor/leap.nvim',
        config = function()
            require('leap').create_default_mappings()
            require('leap').opts.special_keys.prev_target = '<bs>'
            require('leap').opts.special_keys.prev_group = '<bs>'
            require('leap.user').set_repeat_keys('<cr>', '<bs>')
        end
    },

    -- arrow: bookmark files and locations in files
    {
        "otavioschwanck/arrow.nvim",
        dependencies = {
            { "nvim-tree/nvim-web-devicons" },
        },
        opts = {
            show_icons = true,
            leader_key = 'M',        -- Recommended to be a single key
            buffer_leader_key = 'm', -- Per Buffer Mappings
        }
    },

    -- file system navigation
    {
        'kyazdani42/nvim-tree.lua',
        config = function()
            local HEIGHT_RATIO = 0.8
            local WIDTH_RATIO = 0.5
            require('nvim-tree').setup({
                hijack_netrw = true,   -- default
                hijack_cursor = false, -- default
                disable_netrw = true,
                respect_buf_cwd = true,
                sync_root_with_cwd = true,
                view = {
                    relativenumber = true,
                    float = {
                        enable = true,
                        open_win_config = function()
                            local screen_w = vim.opt.columns:get()
                            local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
                            local window_w = screen_w * WIDTH_RATIO
                            local window_h = screen_h * HEIGHT_RATIO
                            local window_w_int = math.floor(window_w)
                            local window_h_int = math.floor(window_h)
                            local center_x = (screen_w - window_w) / 2
                            local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
                            return {
                                border = "rounded",
                                relative = "editor",
                                row = center_y,
                                col = center_x,
                                width = window_w_int,
                                height = window_h_int,
                            }
                        end,
                    },
                },
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
                end,
                -- hide certain files
                -- filters = {
                --     custom = { "^.git$" },
                -- },
            })
            vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeToggle<cr>')
        end
    },

    -- tabs
    {
        'akinsho/bufferline.nvim',
        config = function()
            local bufferline = require('bufferline')
            bufferline.setup({
                options = { mode = 'buffers' },
            })
        end
    },
    {
        'echasnovski/mini.bufremove',
        config = function()
            require('mini.bufremove').setup()
            vim.keymap.set('n', '<leader>w', '<cmd>lua pcall(MiniBufremove.delete)<cr>')
        end
    },

    -- trouble: diagnostics windows
    {
        "folke/trouble.nvim",
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle win.size=0.1<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle win.size=0.1 filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>xs",
                "<cmd>Trouble symbols toggle focus=false win.size=0.25 win.position=right<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>xl",
                "<cmd>Trouble lsp toggle focus=false win.size=0.25 win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    },

    -- telescope: fzf search for EVERYTHING
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    {
        'nvim-telescope/telescope.nvim',
        config = function()
            -- fzf for a pattern in the current file
            vim.keymap.set('n', '<leader>fs', '<cmd>Telescope current_buffer_fuzzy_find<cr>')
            -- grep for a pattern in current directory
            vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
            -- search opened buffers
            vim.keymap.set('n', '<leader>fo', '<cmd>Telescope buffers<cr>')
            -- search files in current directory
            vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
            -- search recent files
            vim.keymap.set('n', '<leader>fr', '<cmd>Telescope oldfiles<cr>')
            -- search diagnostic messages
            vim.keymap.set('n', '<leader>fd', '<cmd>Telescope diagnostics<cr>')
            -- search in clipboard
            vim.keymap.set('n', '<leader>fy', '<cmd>Telescope neoclip<cr>')
        end
    },
    {
        'AckslD/nvim-neoclip.lua',
        config = true
    },

    -- treesitter: syntax highlighting, indentation, class and function objects
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
                -- ensure_installed = {
                --     'lua', 'bash', 'c', 'cpp', 'python', 'go', 'javascript', 'typescript',
                -- },
            })
        end
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects'
    },

    -- mason: easy managing of installed LSPs / Formatters
    {
        'williamboman/mason.nvim',
        config = true
    },
    {
        'williamboman/mason-lspconfig.nvim',
        config = function()
            require('mason-lspconfig').setup({
                ensure_installed = {
                    "lua_ls", "ruff", "gopls", "eslint"
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

    -- lspconfig: setup commands to interact with LSPs - code completion, diagnostics, etc.
    {
        'neovim/nvim-lspconfig',
        config = function()
            vim.api.nvim_create_autocmd('LspAttach', {
                desc = 'LSP actions',
                callback = function(event)
                    local bufmap = function(mode, lhs, rhs)
                        local opts = { buffer = event.buf }
                        vim.keymap.set(mode, lhs, rhs, opts)
                    end

                    -- Displays hover information about the symbol under the cursor
                    bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')

                    -- Jump to the definition
                    bufmap('n', '<leader>jd', '<cmd>lua vim.lsp.buf.definition()<cr>')

                    -- Jump to declaration
                    bufmap('n', '<leader>jD', '<cmd>lua vim.lsp.buf.declaration()<cr>')

                    -- Jumps to the definition of the type symbol
                    bufmap('n', '<leader>jtd', '<cmd>lua vim.lsp.buf.type_definition()<cr>')

                    -- Lists all the implementations for the symbol under the cursor
                    bufmap('n', '<leader>ji', '<cmd>lua vim.lsp.buf.implementation()<cr>')

                    -- Lists all the references
                    bufmap('n', '<leader>jr', '<cmd>lua vim.lsp.buf.references()<cr>')

                    -- Displays a function's signature information
                    bufmap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')

                    -- Renames all references to the symbol under the cursor
                    bufmap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>')

                    -- Selects a code action available at the current cursor position
                    bufmap({ 'n', 'x' }, '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>')

                    -- Show diagnostics in a floating window
                    bufmap('n', '<leader>d', '<cmd>lua vim.diagnostic.open_float()<cr>')

                    -- Move to the previous diagnostic
                    bufmap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')

                    -- Move to the next diagnostic
                    bufmap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')
                end
            })
        end
    },

    -- conform: indicate which formatters to use, and automatic formatting
    {
        'stevearc/conform.nvim',
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    python = { "ruff" },
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

    -- cmp: autocomplete!
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
                    -- keyword_length = # of chars needed for suggestions
                    { name = 'copilot',  keyword_length = 1 },
                    { name = 'nvim_lsp', keyword_length = 2 },
                    { name = 'buffer',   keyword_length = 2 },
                    { name = 'luasnip',  keyword_length = 2 },
                    { name = 'path',     keyword_length = 2 },
                },
                window = {
                    documentation = cmp.config.window.bordered()
                },
                formatting = {
                    fields = { 'menu', 'abbr', 'kind' },
                    format = function(entry, item)
                        local menu_icon = {
                            copilot = 'GPT',
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
                },
                experimental = { ghost_text = true }
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

    -- snippets! (for autocomplete)
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
    {
        'zbirenbaum/copilot.lua',
        config = function()
            require("copilot").setup({
                suggestion = { enabled = false },
                panel = { enabled = false },
            })
        end
    },
    {
        'zbirenbaum/copilot-cmp',
        config = true
    },
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

-- clangd lsp setup
require("lspconfig").clangd.setup {
    cmd = {
        "clangd",
        "--offset-encoding=utf-16",
    },
}

-- use python LSP from conda if in virtual env
local function isempty(s)
    return s == nil or s == ""
end
local function use_if_defined(val, fallback)
    return val ~= nil and val or fallback
end
local conda_prefix = os.getenv("CONDA_PREFIX")
if not isempty(conda_prefix) then
    vim.g.python_host_prog = use_if_defined(vim.g.python_host_prog, conda_prefix .. "/bin/python")
    vim.g.python3_host_prog = use_if_defined(vim.g.python3_host_prog, conda_prefix .. "/bin/python3")
else
    vim.g.python_host_prog = use_if_defined(vim.g.python_host_prog, "python")
    vim.g.python3_host_prog = use_if_defined(vim.g.python3_host_prog, "python3")
end
