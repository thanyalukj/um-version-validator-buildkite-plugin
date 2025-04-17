# UM Version Validator Buildkite Plugin

The UM Version Validator plugin provides the following functionalities:

- Validates the publish version against the version on the `base_branch`.
- Allows developers to release a non-alpha version without requiring an intermediate alpha version if the pull request is tagged with the label `skip-alpha`.

## Example Usage

```yml
steps:
  - label: Validate Version
    plugins:
        - ssh://git@github.com/thanyalukj/um-version-validator-buildkite-plugin.git#v1.0.1:
            platform: 'android-contract'
            base_branch: $BUILDKITE_PULL_REQUEST_BASE_BRANCH
            current_branch: $BUILDKITE_BRANCH
    agents:
      queue: build
```

## Configuration

### `platform` (Required, string)

Specifies the UM platform. Accepted values are: `android-contract`, `android-library`, `ios-contract`, `ios-library`, `react-contract`, and `react-library`.

### `base_branch` (Required, string)

Defines the base branch to merge into. Use `$BUILDKITE_PULL_REQUEST_BASE_BRANCH`.

### `current_branch` (Required, string)

Specifies the current branch. Use `$BUILDKITE_BRANCH`.

## Development

To execute the tests, run the following command:

```shell
docker-compose run --rm tests
```
