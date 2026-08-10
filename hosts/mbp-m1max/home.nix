{ config, pkgs, hostname, ... }:

{
  home.username = "fahimalizain";
  home.homeDirectory = "/Users/fahimalizain";

  home.packages = with pkgs; [
    coreutils     # GNU readlink for Home Manager activation on macOS
  ];

  # CLI/web server (distinct from the openchamber brew cask desktop app).
  # Uses Homebrew node/npm only — not nvm — so the global binary stays on
  # /opt/homebrew/bin regardless of which nvm version a project shell uses.
  home.activation.install-openchamber = ''
    # Homebrew node/npm only (see comment above). No /usr/bin: it would shadow
    # GNU coreutils' readlink for the rest of the HM activation (BSD readlink).
    export PATH="/opt/homebrew/bin:$PATH"
    # Drop nvm shims if a parent shell exported them into the activation env
    unset NVM_DIR NVM_BIN NVM_INC
    if [ -x /opt/homebrew/bin/npm ]; then
      $DRY_RUN_CMD /opt/homebrew/bin/npm install -g @openchamber/web
    else
      echo "install-openchamber: skipping — Homebrew npm missing (brew install node)" >&2
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
  '';
}
