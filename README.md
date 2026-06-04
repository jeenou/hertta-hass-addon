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
