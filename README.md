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
