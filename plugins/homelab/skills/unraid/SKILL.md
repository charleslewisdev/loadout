---
name: unraid
description: "Deploys and inspects containers on an unRAID server: paths, bridge networking, XML templates, User Scripts cron. Container lifecycle stays with the user. Use for any unRAID task."
---

# unRAID server reference

## Read the notes first

If `~/.config/loadout/notes/unraid.md` exists, read it before anything else. It holds this server's facts, such as its address, pool names, services and registry account. A fact in the notes replaces the placeholder here, and the procedures below still apply.

With no notes file, use the placeholders below and ask for a value only when a step needs it. Never guess a pool name or an address.

## Server access

The commands below use `$UNRAID_HOST` for the server's address, so set it in your shell, or use the value from the notes.

- **SSH:** `ssh root@$UNRAID_HOST`
- **Web UI:** `http://$UNRAID_HOST`, where the Docker tab manages containers

## Path conventions

| Path prefix | Description | Use case |
| --- | --- | --- |
| `/mnt/user/` | User shares (FUSE layer) | General access, slower |
| `/mnt/<pool-name>/` | Direct cache pool access | Latency-sensitive appdata |
| `/mnt/disk1/`, `/mnt/disk2/`, ... | Individual array disks | Rarely used directly |
| `/boot/config/` | Persistent USB flash config | Survives reboots |

| Path | Purpose |
| --- | --- |
| `/mnt/user/appdata/<container>/` | Standard appdata location |
| `/boot/config/plugins/dockerMan/templates-user/` | User Docker templates, which persist |

A container needing low-latency I/O, such as a database, should use the direct pool path, `/mnt/<pool-name>/`.

## Docker on unRAID

unRAID doesn't use Docker Compose. Containers are managed through:

1. **XML templates**, the deployment mechanism, stored in `/boot/config/plugins/dockerMan/templates-user/`
2. **The Web UI**, under the Docker tab, for start, stop and edit
3. **The `docker` CLI**, over SSH

### Networking

- Containers use **bridge networking** with IP-based addressing.
- Don't use container names for traffic between containers. Use `$UNRAID_HOST:<port>`.

### GPU passthrough

A container needing the GPU requires this in the template's ExtraParams:

```
--runtime=nvidia --gpus all
```

## Deployment workflow

**Don't create, update, restart or remove containers on unRAID.** The user manages container lifecycle through the Web UI. Claude's role is limited to:

- Building and pushing images from the dev machine
- Copying files to the server, such as templates, plugin files and data
- Reading container status and logs for debugging

### Build and push an image

Run this on the dev machine, not on the server:

```bash
docker build -t <registry-account>/<image>:latest .
docker push <registry-account>/<image>:latest
```

After pushing, tell the user, so they can update through the Web UI.

### Deploy a template

Keep the template in the repo root as `unraid-template.xml`, then:

```bash
scp unraid-template.xml root@$UNRAID_HOST:/boot/config/plugins/dockerMan/templates-user/my-<container>.xml
```

### Copy files to the server

```bash
scp ./file root@$UNRAID_HOST:/mnt/user/appdata/<container>/
rsync -avz --progress ./dir/ root@$UNRAID_HOST:/mnt/user/appdata/<container>/dir/
```

## Read-only checks

```bash
ssh root@$UNRAID_HOST "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
ssh root@$UNRAID_HOST "docker logs --tail 100 <container>"
ssh root@$UNRAID_HOST "docker inspect <container>"
ssh root@$UNRAID_HOST "df -h /mnt/user"
```

## Scheduling with User Scripts

The User Scripts plugin is the way to add persistent scheduled jobs. `update_cron` concatenates every plugin's `*.cron` files into the live crontab at `/etc/cron.d/root`. `crontab -l` shows a different spool, so verify jobs in `/etc/cron.d/root`.

To add a job:

1. Create `/boot/config/plugins/user.scripts/scripts/<name>/` with two files: `name`, the display name, and `script`, the bash script.
2. Append to `/boot/config/plugins/user.scripts/customSchedule.cron`:

   ```
   <cron-expr> /usr/local/emhttp/plugins/user.scripts/startCustom.php /boot/config/plugins/user.scripts/scripts/<name>/script > /dev/null 2>&1
   ```

3. Add a matching entry to `/boot/config/plugins/user.scripts/schedule.json`, with `"frequency": "custom"` and `"custom": "<cron-expr>"`, so the Web UI stays consistent.
4. Run `update_cron` to activate it. Boot re-applies it from the flash `.cron` files.

Two traps:

- `/boot` is vfat, so the exec bit doesn't stick. Test with `bash <script>`, which is how `startCustom.php` runs it.
- Log to `/mnt/user/appdata/`, never to `/boot`, because writes wear the flash.

## Template XML

- Use `bridge` networking mode.
- Map volumes with `/mnt/user/appdata/<container>/` as the host path, or the direct pool path for performance-critical data.
- Use the `WebUI` element for the container's web interface URL.
- Port mappings use `<Port>` elements with `Host` and `Container` attributes.

## Troubleshooting

- **Container won't start:** check `docker logs <name>`, and look for port conflicts in `docker ps`.
- **Permission issues:** unRAID Docker runs as root by default, so check whether the container drops privileges.
- **Slow I/O:** check that the container uses a direct pool path, and not `/mnt/user/`.
- **Template missing from the UI:** confirm the XML is in `templates-user/`, then refresh the Docker tab.
