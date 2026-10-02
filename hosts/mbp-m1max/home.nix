{ config, pkgs, hostname, ... }:

{
  home.username = "fahimalizain";
  home.homeDirectory = "/Users/fahimalizain";

  home.packages = with pkgs; [
    coreutils     # GNU readlink for Home Manager activation on macOS
  ];

  # Agent CLI toolchain. Homebrew node/npm only — not nvm — so the global
  # binaries stay on /opt/homebrew/bin regardless of which nvm version a
  # project shell uses.
  # - @openchamber/web: CLI/web server (distinct from the openchamber brew cask
  #   desktop app in default.nix).
  # - @getpaseo/cli: Paseo CLI.
  # - @opencode-ai/browser-control: Browser Control CLI + MCP server; drives the
  #   real Chrome via the unpacked extension shipped in the npm package. Load it
  #   once from "$(npm root -g)/@opencode-ai/browser-control/extension/dist" and
  #   reload it after any npm upgrade. Agent skill:
  #   npx skills add anomalyco/browser-control --skill browser-control -g
  home.activation.install-npm-packages = ''
    # No /usr/bin: it would shadow GNU coreutils' readlink for the rest of the
    # HM activation (BSD readlink).
    export PATH="/opt/homebrew/bin:$PATH"
    # Drop nvm shims if a parent shell exported them into the activation env
    unset NVM_DIR NVM_BIN NVM_INC
    if [ -x /opt/homebrew/bin/npm ]; then
      $DRY_RUN_CMD /opt/homebrew/bin/npm install -g @openchamber/web @getpaseo/cli @opencode-ai/browser-control
    else
      echo "install-npm-packages: skipping — Homebrew npm missing (brew install node)" >&2
    fi
  '';

  home.shellAliases = {
    aerospace-ghost = "aerospace list-windows --all --json | jq -r '.[] | select(.\"window-title\"==\"\") | .\"window-id\"' | xargs -n1 aerospace close --window-id";
  };

  home.sessionVariables = {
    JAVA_HOME = "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home";
    ANDROID_HOME = "$HOME/Library/Android/sdk";
    NVM_DIR = "$HOME/.nvm";
  };

  programs.zsh.envExtra = ''
    # nvm: manage multiple Node.js versions
    export NVM_DIR="$HOME/.nvm"
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  '';

  programs.zsh.initContent = ''
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"

    # nvm: manage multiple Node.js versions
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
    [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

    export PATH="$HOME/.grok/bin:$PATH"
    fpath=("$HOME/.grok/completions/zsh" $fpath)
    autoload -Uz compinit && compinit -C

    # Android SDK toolchain.  ANDROID_HOME is duplicated from
    # home.sessionVariables above so this block stands on its own; the SDK's
    # platform-tools then go first so adb/fastboot win over /opt/homebrew/bin
    # (the android-platform-tools cask is deliberately not installed, and both
    # scrcpy and Maestro resolve adb from PATH).
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export PATH="$ANDROID_HOME/platform-tools:$PATH"
  '';
}
