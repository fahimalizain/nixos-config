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
   this repo. On the ThinkPad, print it:

   ```bash
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```

   Then, on this machine, paste it into a root-only file:

   ```bash
   sudo install -d -m 700 /var/lib/rancher/k3s
   read -rsp 'Paste k3s token: ' K3S_TOKEN; echo
   printf '%s\n' "$K3S_TOKEN" \
     | sudo install -m 600 /dev/stdin /var/lib/rancher/k3s/agent-token
   unset K3S_TOKEN
   ```

   `read -s` keeps the token out of shell history. The ThinkPad does not run
   sshd, so there is no one-line `ssh` version of this step.

3. Restart k3s so it picks up the token:

   ```bash
   sudo systemctl restart k3s
   ```

4. Apply the worker role label from the server:

   ```bash
   sudo k3s kubectl label node msigl738se node-role.kubernetes.io/worker=
   ```

   The label cannot be set through k3s `nodeLabels`: kubelet rejects
   `node-role.kubernetes.io/*` in `--node-label` on Kubernetes 1.35.

5. Verify from the server:

   ```bash
   sudo k3s kubectl get nodes -o wide
   sudo k3s kubectl get node msigl738se --show-labels
   ```

   `msigl738se` should be `Ready`, have the worker label, and show
   `INTERNAL-IP` `100.95.21.21`.

## Notes

- k3s is pinned to the tailnet on both nodes:
  - this host: `100.95.21.21`
  - server: `100.98.242.77`

  kubelet, the API endpoint, and flannel all use these addresses, so traffic
  stays on `tailscale0` and the firewall never opens on the LAN. When both
  machines are local, Tailscale still carries the encrypted packets directly
  over the LAN (check with `tailscale status`).

  Tailscale IPs are stable for the life of the device, but if one is ever
  reassigned, update `nodeIP` and the server's `tlsSANs` in both host configs
  and rebuild both machines.

- The API is also reachable at
  `https://thinkpad-nixos.tail8395b3.ts.net:6443`; the MagicDNS name is in the
  server certificate as well as the Tailscale IP.
- Unlike the ThinkPad, this host does not enable the battery charge threshold
  module (the MSI embedded controller does not expose that interface).
- `/etc/nixos` is a symlink to `~/nixos-config`, matching the ThinkPad setup.
  On a reinstall, recreate it once after the first switch:

  ```bash
  sudo mv /etc/nixos /etc/nixos.backup
  sudo ln -s ~/nixos-config /etc/nixos
  ```
