{ config, pkgs, lib, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  # npm's writable global prefix. nix node's default global dir lives in the
  # read-only store, so point npm at a home dir we own and put its bin on PATH.
  npmPrefix = "${config.home.homeDirectory}/.npm-global";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    gh        # GitHub CLI
    lazygit
    neovim

    # node development
    nodejs_24 # install Node.js 24 along with npm and npx
    pnpm      # fast Node package manager (not via corepack; the Nix store is read-only so `corepack enable` can't place shims)
    bun       # all-in-one JS runtime, bundler, test runner, and package manager

    # ai coding agents
    opencode  # AI coding agent for the terminal - powers the `oc` alias and is auto-detected by Open Design

    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  # Route npm global installs into a writable prefix (the nix store is
  # read-only) and put its bin on PATH so manually `npm install -g`'d CLIs run.
  home.sessionVariables.NPM_CONFIG_PREFIX = npmPrefix;
  home.sessionPath = [ "${npmPrefix}/bin" ];

  # These ship only on npm (no nixpkgs/brew package), so keep them installed
  # and current on every rebuild via their supported install method.
  # command-code's binary is `cmd` (a deliberately generic name from upstream).
  home.activation.installNpmGlobalClis = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export NPM_CONFIG_PREFIX="${npmPrefix}"
    # Put node on PATH so npm-spawned postinstall scripts (e.g. protobufjs,
    # pulled in by command-code) can call `node`. Without this the activation
    # runs in a context where `node` isn't found and the install fails.
    export PATH="${pkgs.nodejs_24}/bin:$PATH"
    $DRY_RUN_CMD mkdir -p "$NPM_CONFIG_PREFIX/bin"
    $DRY_RUN_CMD "${pkgs.nodejs_24}/bin/npm" install -g @dokploy/cli command-code
  '';

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
      oc = "opencode --auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Git identity - declared here so commits are attributed correctly.
  # See README "Make it yours" -> Git identity.
  programs.git = {
    enable = true;
    settings.user = {
      name = "wmhafiz";
      email = "fizyboy@gmail.com";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
