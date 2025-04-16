# UM Version Validator Buildkite Plugin

Validates your publish version

## Example

```yml
steps:
  - label: Check Version
    plugins:
        - ssh://git@github.com/thanyalukj/um-version-validator-buildkite-plugin.git#v1.0.1:
            platform: 'android-contract'
            base_branch: $$BUILDKITE_PULL_REQUEST_BASE_BRANCH
            current_branch: $$BUILDKITE_BRANCH
            pr_labels: $$BUILDKITE_PULL_REQUEST_LABELS
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
