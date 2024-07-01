# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Bun runtime support. ✨

## v2.2.0 - 2024-02-29

### Added

- Websocket support with the new `glen.websocket` API & `glen/ws` module.

## v2.1.1 - 2024-02-17

### Changed

- Improved `log` middleware
  - More specific response colors for redirectional and informational responses
  - Logs the amount of time the handler takes to respond in milliseconds

## v2.1.0 - 2024-02-09

### Added

- Exported types from `conversation`.
  - `JsRequest`
  - `JsResponse`
  - `JsReadableStream`

## v2.0.0 - 2024-02-05

### Added

- Changelog to keep track of changes and releases

### Changed

- Argument ordering of `serve` and `custom_serve` to be `use`-friendly and more idiomatic.
  > ```gleam
  > // Before
  > pub fn main() {
  >   glen.serve(handle_req, 8000)
  > }
  >
  > // Now
  > pub fn main() {
  >   glen.serve(8000, handle_req)
  > }
  > ```
  >
  > ```gleam
  > // Before
  > pub fn main() {
  >   glen.custom_serve(handle_req, my_serve, 8000)
  > }
  >
  > // Now
  > pub fn main() {
  >   glen.serve(8000, my_serve, handle_req)
  > }
  > ```

### Removed

- `custom_serve` function in favor of `convert_request` and `convert_response` (more info in the readme).

## Pre-v2.0.0

Pre v2.0.0 versions are not documented in the changelog.
