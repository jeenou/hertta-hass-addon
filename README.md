# Hertta add-on for Home Assistant

## Install in Home Assistant

The downloadable add-on image is available for `amd64` and `aarch64` Home
Assistant systems, including 64-bit Raspberry Pi 4 installations.

1. Publish the image by running the `Publish Home Assistant add-on` GitHub
   Actions workflow.
2. In Home Assistant, open **Settings > Add-ons > Add-on store**.
3. Open **Repositories** and add:
   `https://github.com/jeenou/hertta-hass-addon`
4. Install and start **Hertta**.

Home Assistant supplies the Core API token automatically. Hertta stores its
settings and model under the persistent add-on `/data` directory.

## Local Docker test

Build the image:

```sh
docker build -t hertta-addon-local .
```

Run it locally:

```sh
docker run --rm -it \
  --name hertta-addon-local \
  -p 4001:4001 \
  -v hertta-addon-data:/data \
  -e HASS_BASE_URL=http://host.docker.internal:8123/api \
  -e HASS_TOKEN=your_home_assistant_token \
  hertta-addon-local
```

Then open http://localhost:4001.

The container starts both services:

- `hertta` GraphQL backend inside the container on `localhost:3030`
- `hass-backend` plus the built frontend on `http://localhost:4001`

For local testing, supply both the Home Assistant API URL and a long-lived
access token. Inside Home Assistant, the add-on automatically uses the
Supervisor API URL and token instead.

To test against a real Home Assistant instance running on your host, pass a long-lived access token:

```sh
docker run --rm -it \
  --name hertta-addon-local \
  -p 4001:4001 \
  -v hertta-addon-data:/data \
  -e HASS_BASE_URL=http://host.docker.internal:8123/api \
  -e HASS_TOKEN=your_home_assistant_token \
  hertta-addon-local
```

If Home Assistant is somewhere else on your network, replace `HASS_BASE_URL` with that address, for example `http://192.168.1.50:8123/api`.

## Dev Docker

The dev setup runs three containers:

- React frontend with hot reload on http://localhost:3000
- Hass backend with automatic Rust rebuilds on http://localhost:4001
- Hertta GraphQL server with automatic Rust rebuilds on http://localhost:3030

Start it from PowerShell:

```powershell
$env:HASS_BASE_URL="http://192.168.1.110:8123/api"; $env:HASS_TOKEN="YOUR_TOKEN_HERE"; docker compose -f docker-compose.dev.yml up --build
```

After the initial build:

```powershell
docker compose -f docker-compose.dev.yml up
```

Stop and remove the dev containers:

```powershell
docker compose -f docker-compose.dev.yml down
```

Check service status and logs:

```powershell
docker compose -f docker-compose.dev.yml ps
docker compose -f docker-compose.dev.yml logs -f
```
