{ ... }:

{
  # User account settings (host-specific)
  home.username = "fahimalizain";
  home.homeDirectory = "/home/fahimalizain";

  # 1Password's SSH agent socket. Requires the app to be signed in and
  # Settings → Developer → "Use the SSH Agent" enabled.
  home.sessionVariables = {
    SSH_AUTH_SOCK = "/home/fahimalizain/.1password/agent.sock";
  };

  # SSH client config (~/.ssh/config). Private keys never touch the disk:
  # they live in 1Password, which signs on the agent's behalf.
  #
  # This replaces the one-line file the 1Password app's "Configure SSH"
  # button writes — do not press that button again, or it will overwrite
  # this managed symlink.
  programs.ssh = {
    enable = true;

    # Do not emit Home Manager's opinionated defaults (ControlMaster no,
    # ServerAlive*, ...). Only the directives below are written; ssh keeps
    # its own upstream defaults for everything else.
    enableDefaultConfig = false;

    # Raw OpenSSH directives. Concrete hosts are emitted first, `*` last,
    # which is the order ssh needs (first value obtained wins).
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityAgent = "~/.1password/agent.sock";
        # Offer only the key below. Without this, ssh would try all 16 keys
        # in the agent and GitHub would abort with "too many authentication
        # failures".
        IdentitiesOnly = "yes";
        # A .pub path is deliberate: there is no private key file to point
        # at. ssh reads the public half and asks the agent to sign with the
        # matching key.
        IdentityFile = "~/.ssh/ThinkPadWin11.pub";
        # Keep GitHub's pinned keys separate so the normal known_hosts stays
        # writable for every other server.
        UserKnownHostsFile = "~/.ssh/known_hosts_github";
      };

      # Every other host: sign with the 1Password agent.
      "*" = {
        IdentityAgent = "~/.1password/agent.sock";
      };
    };
  };

  # Public half of the GitHub key. The private half stays in 1Password;
  # this file exists only so ssh knows which agent key to offer.
  home.file.".ssh/ThinkPadWin11.pub".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILieUm950JC3gpMaivRTY4yNs8LVS7ZmMTwxlyBE2Qnu ThinkPadWin11
  '';

  # GitHub's published host keys, pinned so the first connection neither
  # prompts nor trusts on first use.
  home.file.".ssh/known_hosts_github".text = ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
  '';
}
