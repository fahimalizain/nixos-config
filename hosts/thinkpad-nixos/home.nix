{ ... }:

{
  # User account settings (host-specific)
  home.username = "fahimalizain";
  home.homeDirectory = "/home/fahimalizain";

  # 1Password's SSH agent socket. Requires the app to be signed in with
  # Settings → Developer → "Use the SSH Agent" enabled.
  home.sessionVariables = {
    SSH_AUTH_SOCK = "/home/fahimalizain/.1password/agent.sock";
  };
}
