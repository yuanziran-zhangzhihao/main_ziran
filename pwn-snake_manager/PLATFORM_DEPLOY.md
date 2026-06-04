# pwn-snake_manager Platform Deploy

## Static Registry Image

Use the mirrored static image from the challenge server:

```text
baiziandziran.xyz/ziranan/pwn-snake_manager:ecs-20260604-r1
```

## Image Pull Fallback

If the platform cannot pull from the static registry, use the exported image archive instead:

```bash
docker load -i pwn-snake_manager-image.tar
docker run --rm -p 8000:8000 -e 'FLAG=FLAG{real_flag}' pwn-snake_manager:platform-import-cbb5e762
```

The local archive is:

```text
pwn-snake_manager/deploy/pwn-snake_manager-image.tar
```

The compressed copy is:

```text
pwn-snake_manager/deploy/pwn-snake_manager-image.tar.gz
```

GitHub Actions also uploads `pwn-snake_manager-platform-image`, which contains `pwn-snake_manager-image.tar.gz`.

## GHCR Image

If the platform can pull GHCR, use the fixed SHA tag instead of `latest`:

```text
ghcr.io/ziranan/pwn-snake_manager:sha-cbb5e762794800a186f3f3bb3e1dbfe8cb22d4bf
```

If this fails on the platform, prefer image archive import. The usual causes are GHCR network access, package visibility, or platform-side image cache.
