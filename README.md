# UM Version Validator Buildkite Plugin

Validates your publish version

## Example

```yml
steps:
  - label: Check Version
    plugins:
      - ssh://git@github.com/thanyalukj/um-version-validator-buildkite-plugin#v1.0.0
    agents:
      queue: build
```

## Configuration

### `pattern` (Required, string)

The file name pattern, for example `*.ts`. Supports any pattern supported by [find -name](http://man7.org/linux/man-pages/man1/find.1.html).

## Developing

To run the tests:

```shell
docker-compose run --rm tests
```