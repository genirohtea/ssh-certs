# Ansible Collection - geniroh.ssh_certs

Ansible roles and playbooks for setting up SSH-certificate-based authentication
backed by Bitwarden Secrets Manager (BWS).

Two entry-point scripts wrap the playbooks:

- [`setup_host_server.sh`](setup_host_server.sh) — provisions a remote
  server so that it presents a signed host certificate and trusts the user CA.
- [`setup_user_workstation.sh`](setup_user_workstation.sh) — provisions the
  local workstation so it has a signed user certificate and trusts the host CA.

Both scripts retrieve CA keys from BWS.

## Running the scripts

### Provision a host server

Run from your workstation against the target server. Use `--use_ssh_pass` the
first time, before key-based authentication has been set up (Ansible will then
prompt for the SSH password). On subsequent runs you can drop the flag.

```bash
./setup_host_server.sh \
  --host curie.klaus.geniroh.com \
  --site klaus \
  --env prod \
  --use_ssh_pass \
  --verbose
```

Useful flags:

- `--ansible_user <user>` — user Ansible connects as (default: `root`).
- `--disable_key_check` — bypass strict host key checking. Use after a
  certificate expires and your workstation has been configured to enforce it.
- `--tags <tags>` — run a subset of role tags (`sign_host_key`,
  `accept_user_ca`).

### Provision a user workstation

Run locally against `localhost`. The script writes the signed user certificate
to `~/.ssh/`, adds the host CA to `~/.ssh/known_hosts`, and adds a Host stanza
to `~/.ssh/config`.

```bash
./setup_user_workstation.sh \
  --host localhost \
  --site klaus \
  --env prod \
  --user geniroh \
  --domain "*klaus.geniroh.com" \
  --add_root \
  --verbose
```

Useful flags:

- `--add_root` — include `root` in the certificate principals.
- `--principals <csv>` — extra principals beyond `--user`.
- `--tags <tags>` — run a subset of role tags (`sign_user_key`,
  `accept_host_ca`).

## Using SSH after setup

Once a host has been provisioned with `setup_host_server.sh` and your
workstation has been provisioned with `setup_user_workstation.sh`, regular SSH
works with no extra flags — the workstation's `~/.ssh/config` Host stanza
points `ssh` at the signed user key, the user certificate next to it is
presented automatically, and the `@cert-authority` line in `~/.ssh/known_hosts`
makes the server's host certificate trusted without a TOFU prompt.

```bash
ssh <user>@<host>.<site>.<domain>
# e.g. ssh geniroh@curie.klaus.geniroh.com
```

The user you log in as must be one of the principals baked into the
certificate (`--user`, plus anything from `--principals`, plus `root` if you
passed `--add_root`).

### Verifying it's working

Check what your user certificate actually authorizes:

```bash
ssh-keygen -L -f ~/.ssh/<user>-<env>-<site>-cert.pub
```

Look at the `Principals:`, `Valid:` window, and the CA fingerprint. To confirm
the server is presenting a host certificate (rather than a raw host key), run:

```bash
ssh -v <host> 2>&1 | grep -i 'Server host certificate\|cert-authority'
```

You should see the server's host certificate being accepted via your
`@cert-authority` line.

### When things stop working

- **`Permission denied (publickey)`** — your user certificate has probably
  expired (default lifetime is 395 days). Re-run `setup_user_workstation.sh`
  to mint a new one. The CA itself doesn't need to rotate for this.
- **`Host key verification failed` / cert-authority mismatch** — the host CA
  has rotated but your workstation still trusts the old one. Re-run
  `setup_user_workstation.sh`, which will refresh the `@cert-authority` line
  in `~/.ssh/known_hosts`.
- **Locked out after CA rotation** — re-run `setup_host_server.sh` with
  `--disable_key_check` to bypass strict host key checking long enough to
  re-provision the server.

## Rotating keys

CA keys are managed by the
[`bitwarden-secrets-manager`](../terraform/deployments/bitwarden-secrets-manager)
Terraform deployment, which uses a `time_rotating` resource to rotate the
`tls_private_key` resources on a one-year cadence. When a rotation happens (or
when you force one), every workstation and server has to pick up the new CA
material.

**Rotate servers before workstations.** If you rotate workstation trust first,
existing host certificates signed by the old host CA will stop being trusted
and you may lock yourself out.

1. **Rotate the CA keys in Terraform**

   ```bash
   cd terraform/deployments/bitwarden-secrets-manager
   tofu apply
   ```

   To force an early rotation, taint the `time_rotating` resource:

   ```bash
   tofu taint time_rotating.key_rotation_interval
   tofu apply
   ```

   After the apply, copy the refreshed `ansible_bws_secret_ids` block into
   [`roles/ssh_certificates/vars/main.yml`](roles/ssh_certificates/vars/main.yml):

   ```bash
   tofu output -raw ansible_bws_secret_ids
   ```

2. **Re-run `setup_host_server.sh` against every server.** This pulls the new
   host CA private key, signs a fresh host certificate, and updates the
   server's trusted user CA.

   ```bash
   ./setup_host_server.sh --host <server> --site <site> --env <env>
   ```

3. **Re-run `setup_user_workstation.sh` on every workstation.** This pulls the
   new host CA public key into `~/.ssh/known_hosts` and signs a fresh user
   certificate.

   ```bash
   ./setup_user_workstation.sh --host localhost --site <site> --env <env> \
     --user <user> --domain "*<site>.<domain>" --add_root
   ```

   If a workstation's existing certificate has already expired and host key
   checking is enforced, run the server step with `--disable_key_check` so you
   can SSH in to recover.
