# Basic configuration
The RESTful API and web interface are enabled by installing the `oxidized-web`
gem and configuring the `extensions.oxidized-web:` section in the configuration
file:
```yaml
extensions:
  oxidized-web:
    load: true
    # enter your configuration here
```

You can set the following parameter:
- `load`: `true`/`false`: Enables or disables the `oxidized-web` extension
  (default: `false`)
- `listen`: Specifies the interface to bind to (default: `127.0.0.1`). Valid
  options:
  - `127.0.0.1`: Allows IPv4 connections from localhost only
  - `'[::1]'`: Allows IPv6 connections from localhost only
  - `<IPv4-Address>` or `'[<IPv6-Address>]'`: Binds to a specific interface
  - `0.0.0.0`: Binds to any IPv4 interface
  - `'[::]'`:  Binds to any IPv4 and IPv6 interface
- `port`: Specifies the TCP port to listen to (default: `8888`)
- `url_prefix`: Defines a URL prefix (default: no prefix)
- `vhosts`: A list of virtual hosts to listen to. If not specified, it will
  respond to any virtual host.

## Examples

```yaml
# Listen on http://[::1]:8888/
extensions:
  oxidized-web:
    load: true
    listen: '[::1]'
    port: 8888
```

```yaml
# Listen on http://127.0.0.1:8888/
extensions:
  oxidized-web:
    load: true
    listen: 127.0.0.1
    port: 8888
```

```yaml
# Listen on http://[2001:db8:0:face:b001:0:dead:beaf]:8888/oxidized/
extensions:
  oxidized-web:
    load: true
    listen: '[2001:db8:0:face:b001:0:dead:beaf]'
    port: 8888
    url_prefix: oxidized
```

```yaml
# Listen on http://10.0.0.1:8000/oxidized/
extensions:
  oxidized-web:
    load: true
    listen: 10.0.0.1
    port: 8000
    url_prefix: oxidized
```

```yaml
# Listen on any interface to http://oxidized.rocks:8888 and
# http://oxidized:8888
extensions:
  oxidized-web:
    load: true
    listen: '[::]'
    url_prefix: oxidized
    vhosts:
     - oxidized.rocks
     - oxidized
```

# Hide node vars
Some node vars (enable, password) can contain sensible data. You can list the
vars to be hidden under `hide_node_vars`:
```yaml
extensions:
  oxidized-web:
    load: true
    hide_node_vars:
     - enable
     - password
```