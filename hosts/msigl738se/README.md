# msigl738se — MSI GL73 8SE

k3s agent (worker) joining the control plane on `thinkpad-nixos` over
Tailscale. Everything declarative lives in `default.nix`; this file covers the
one-time steps that cannot be committed to a public repo.

## First switch

On this machine, from `~/nixos-config`:

```bash
sudo nixos-rebuild switch --flake .#msigl738se
```

This installs Tailscale and starts k3s. k3s will restart until the join token
from the next section exists.

## Join the cluster

1. Log in to Tailscale:

   ```bash
   sudo tailscale up
   ```

2. Copy the node token from the server. The token is a secret, so it is not in
   this repo:

   ```bash
   sudo install -d -m 700 /var/lib/rancher/k3s
   ssh -t fahimalizain@thinkpad-nixos.tail8395b3.ts.net \
     'sudo cat /var/lib/rancher/k3s/server/node-token' \
     | tr -d '\r' \
     | sudo install -m 600 /dev/stdin /var/lib/rancher/k3s/agent-token
   ```

   `ssh -t` gives the remote `sudo` a terminal for its password prompt;
   `tr -d '\r'` strips the carriage returns that the remote pty adds.

3. Restart k3s so it picks up the token:

   ```bash
   sudo systemctl restart k3s
   ```

4. Verify from the server:

   ```bash
   sudo k3s kubectl get nodes
   ```

   `msigl738se` should appear with the `node-role.kubernetes.io/worker` label
   and become `Ready` once flannel and kubelet are up.

## Notes

- The agent reaches the API at `https://thinkpad-nixos.tail8395b3.ts.net:6443`.
  It does not open any ports on the LAN; kubelet and flannel traffic is allowed
  on `tailscale0` only.
- Unlike the ThinkPad, this host does not enable the battery charge threshold
  module (the MSI embedded controller does not expose that interface).
- `/etc/nixos` is a symlink to `~/nixos-config`, matching the ThinkPad setup.
  On a reinstall, recreate it once after the first switch:

  ```bash
  sudo mv /etc/nixos /etc/nixos.backup
  sudo ln -s ~/nixos-config /etc/nixos
  ```
