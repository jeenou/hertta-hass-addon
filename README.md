Hertta add-on for Home Assistant

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
  hertta-addon-local
```

Then open http://localhost:4001.

The container starts both services:

- `hertta` GraphQL backend inside the container on `localhost:3030`
- `hass-backend` plus the built frontend on `http://localhost:4001`

By default, the local container uses:

- `HASS_BASE_URL=http://host.docker.internal:8123/api`
- `HASS_TOKEN=dummy-token`

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
