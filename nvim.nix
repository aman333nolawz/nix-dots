{ config, pkgs, lib, inputs, ... }:
let
  bufferKeys = builtins.genList (i: {
    key = "<A-${toString (i + 1)}>";
    mode = "n";
    desc = "Switch to buffer ${toString (i + 1)}";
    action = "<Cmd>:BufferLineGoToBuffer ${toString (i + 1)}<CR>";
  }) 9;
in
{
  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;
        syntaxHighlighting = true;
        binds.whichKey.enable = true;

        utility.snacks-nvim = {
          enable = true;
          setupOpts = {
            animate.enabled = true;
            explorer.enabled = true;
            bigfile.enabled = true;
            image = {
              enabled = true;
              doc.inline = false;
            };
            indent.enabled = true;
            input.enabled = true;
            notifier.enabled = true;
            quickfile.enabled = true;
            scope.enabled = true;
            scroll.enabled = true;
            words.enabled = true;
            picker.enabled = true;
            lazygit.enabled = true;
            zen.enabled = true;

            statuscolumn = {
              enabled = true;
              folds.open = true;
            };

            styles.notification.wo.wrap = true;
          };
        };

        keymaps = [
          {
            key = "<leader>y";
            mode = [ "n" "v" ];
            desc = "Yank to system clipboard";
            action = "\"+y";
          }
          {
            key = "<leader>p";
            mode = [ "n" "v" ];
            desc = "Paste from system clipboard";
            action = "\"+p";
          }
          {
            key = "<leader>P";
            mode = "n";
            desc = "Paste from system clipboard";
            action = "\"+P";
          }
          {
            key = "<A-c>";
            mode = "n";
            desc = "Close current buffer";
            action = "<Cmd>:bdelete<CR>";
          }
          {
            key = "<C-S>";
            mode = [ "n" "i" "v" ];
            action = "<Cmd>:w!<CR>";
          }
          {
            key = "J";
            mode = "v";
            action = "<Cmd>:m '>+1<CR>gv=gv";
          }
          {
            key = "K";
            mode = "v";
            action = "<Cmd>:m '<-2<CR>gv=gv";
          }
          {
            key = "<C-;>";
            mode = "n";
            action = "A;<esc>";
          }
          {
            key = "<Tab>";
            mode = "n";
            desc = "Switch to next buffer";
            action = "<Cmd>:BufferLineCycleNext<CR>";
          }
          {
            key = "<S-Tab>";
            mode = "n";
            desc = "Switch to previous buffer";
            action = "<Cmd>:BufferLineCyclePrev<CR>";
          }
          {
            key = "<leader>h";
            mode = "n";
            desc = "Notification History";
            lua = true;
            action = "function() Snacks.picker.notifications() end";
          }
          {
            key = "<leader>e";
            mode = "n";
            desc = "File Explorer";
            lua = true;
            action = "function() Snacks.explorer() end";
          }
          {
            key = "<C-`>";
            mode = [ "n" "i" "t" ];
            desc = "Toggle Terminal";
            lua = true;
            action = "function() Snacks.terminal() end";
          }
          {
            key = "<leader>z";
            mode = "n";
            desc = "Toggle Zen Mode";
            lua = true;
            action = "function() Snacks.zen() end";
          }
          {
            key = "<leader>gg";
            mode = "n";
            desc = "Lazygit";
            lua = true;
            action = "function() Snacks.lazygit() end";
          }
        ] ++ bufferKeys;


        dashboard.alpha.enable = true;
        theme = {
          enable = true;
          name = "tokyonight";
          style = "night";
        };

        ui = {
          colorizer.enable = true;
          noice.enable = true;
          nvim-ufo.enable = true;
        };

        visuals = {
          indent-blankline.enable = true;
          rainbow-delimiters.enable = true;
        };

        statusline.lualine.enable = true;
        tabline.nvimBufferline = {
          enable = true;
          setupOpts.options = {
            numbers = "none";
            indicator = {
                icon = "▎";
                style = "icon";
            };
          };
        };

        options = {
          laststatus = 3;
          nu = true;
          relativenumber = true;
          scrolloff = 10;
          expandtab = true;
          shiftwidth = 2;
          smartindent = true;
          tabstop = 2;
          softtabstop = 2;
          wrap = false;
          swapfile = false;
          backup = false;
          foldcolumn = "0";
          foldlevel = 99;
          foldlevelstart = 99;
          foldenable = true;
          signcolumn = "yes:2";
          pumblend = 30;
        };

        autopairs.nvim-autopairs.enable = true;
        autocomplete = {
          blink-cmp = {
            enable = true;
            friendly-snippets.enable = true;
          };
        };

        assistant = {
          avante-nvim.enable = true;
          chatgpt.enable = true;
          copilot = {
            enable = true;
            cmp.enable = true;
            setupOpts = {
              suggestion = {
                enabled = true;
                auto_trigger = true;
                hide_during_completion = true;
              };
            };
          };
        };

        utility = {
          multicursors.enable = true;
          surround.enable = true;
          leetcode-nvim.enable = true;
          mkdir.enable = true;
          motion.flash-nvim.enable = true;
        };

        languages = {
          enableTreesitter = true;
          enableFormat = true;
          bash.enable = true;
          python.enable = true;
          rust.enable = true;
          html.enable = true;
          typescript.enable = true;
          markdown = {
            enable = true;
            extensions.markview-nvim.enable = true;
          };
          svelte.enable = true;
          tsx.enable = true;
          go.enable = true;
        };

        treesitter = {
          enable = true;
          fold = true;
          highlight.enable = true;
          indent.enable = true;
          textobjects.enable = true;
        };

        diagnostics = {
          enable = true;
          #config.virtual_lines = true;
        };

        git.enable = true;
        comments.comment-nvim.enable = true;
        formatter.conform-nvim.enable = true;
        lsp.enable = true;
        lsp.formatOnSave = true;
        debugger.nvim-dap.enable = true;
        debugger.nvim-dap.ui.enable = true;
      };
    };
  };
}
