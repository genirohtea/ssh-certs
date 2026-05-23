# ssh_certificates

Sets up user workstations and host servers to use SSH certificates.

The role has four sub-tasks. Each is opt-in via a boolean variable, so the same role works on both ends of the trust relationship:

- `sign_host_key` — sign the server's host key with the host CA, install `HostCertificate` in `/etc/ssh/sshd_config`, and restart sshd.
- `accept_user_ca` — install the user CA public key on a server and add `TrustedUserCAKeys` to `/etc/ssh/sshd_config`, so the server accepts user-cert-based logins.
- `sign_user_key` — generate (if missing) an Ed25519 key on a workstation and sign it with the user CA, producing `~/.ssh/<name>-cert.pub`.
- `accept_host_ca` — add a `@cert-authority` line to the workstation's `~/.ssh/known_hosts` and append a `Host` stanza to `~/.ssh/config`.

## Requirements

Ansible 2.14+ on the control node and the following collections (declared in `meta/main.yml` and `requirements.yml`):

```bash
ansible-galaxy collection install community.crypto community.general
```

The role needs CA keys stored in Bitwarden Secrets Manager: set the env var `BWS_ACCESS_TOKEN` on the control node and override `bws_secret_ids` with the IDs of your own secrets. The role uses
`community.general.bitwarden_secrets_manager`.

The Terraform configuration in this repo (`terraform/deployments/`) creates the matching BWS project and rotates the keys.

## Role Variables

### Sub-task toggles (default `false`)

| Variable         | Where it runs | What it does                           |
| ---------------- | ------------- | -------------------------------------- |
| `sign_host_key`  | host server   | Sign the host key, configure sshd      |
| `accept_user_ca` | host server   | Trust user certs signed by the user CA |
| `sign_user_key`  | workstation   | Generate + sign the user's SSH key     |
| `accept_host_ca` | workstation   | Trust host certs signed by the host CA |

### Required vars (no defaults — must be set by the consumer)

| Variable     | Used by                           | Example                   |
| ------------ | --------------------------------- | ------------------------- |
| `env`        | all sub-tasks                     | `prod`                    |
| `site`       | all sub-tasks                     | `homelab`                 |
| `user`       | `sign_user_key`, `accept_host_ca` | `alice`                   |
| `domain`     | `accept_host_ca`                  | `*.example.com`           |
| `identity`   | `sign_host_key`, `sign_user_key`  | `curie`                   |
| `principals` | `sign_host_key`, `sign_user_key`  | `curie,curie.example.com` |
| `expiry`     | `sign_host_key`, `sign_user_key`  | `+395d`                   |

### Optional vars (have defaults — override as needed)

| Variable         | Default        | Notes                                     |
| ---------------- | -------------- | ----------------------------------------- |
| `service_name`   | `sshcerts`     | Namespacing prefix for vaults and markers |
| `bws_secret_ids` | (placeholders) | Replace with your own BWS secret UUIDs    |

## Dependencies

No role dependencies. Collection dependencies are declared in `meta/main.yml` and `requirements.yml`.

## Example Playbooks

### Host server

```yaml
- hosts: servers
  roles:
    - role: ssh_certificates
      vars:
        sign_host_key: true
        accept_user_ca: true
        env: prod
        site: homelab
        identity: "{{ inventory_hostname_short }}"
        principals: "{{ inventory_hostname }},{{ inventory_hostname_short }}"
        expiry: "+395d"
        bws_secret_ids:
          hostca-priopenssh: "your-bws-secret-uuid"
          hostca-pubopenssh: "your-bws-secret-uuid"
          userca-priopenssh: "your-bws-secret-uuid"
          userca-pubopenssh: "your-bws-secret-uuid"
```

### User workstation

```yaml
- hosts: localhost
  connection: local
  roles:
    - role: ssh_certificates
      vars:
        sign_user_key: true
        accept_host_ca: true
        env: prod
        site: homelab
        user: alice
        domain: "*.homelab.example.com"
        identity: alice
        principals: "alice"
        expiry: "+90d"
        bws_secret_ids:
          hostca-priopenssh: "your-bws-secret-uuid"
          hostca-pubopenssh: "your-bws-secret-uuid"
          userca-priopenssh: "your-bws-secret-uuid"
          userca-pubopenssh: "your-bws-secret-uuid"
```

### Consuming from another repo

If you install this role as part of the `geniroh.ssh_certs` collection:

```bash
ansible-galaxy collection install git+https://github.com/genirohtea/ssh-certs.git
```

Then reference it as `geniroh.ssh_certs.ssh_certificates` in your playbook:

```yaml
- hosts: servers
  roles:
    - role: geniroh.ssh_certs.ssh_certificates
      vars:
        sign_host_key: true
        ...
```

## License

BSD-3-Clause

## Author Information

Maintained at <https://github.com/genirohtea/ssh-certs>.
