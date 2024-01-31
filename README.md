# glen

<img src="https://raw.githubusercontent.com/MystPi/glen/main/assets/glen.png" width="150" align="right" />

[![Package Version](https://img.shields.io/hexpm/v/glen)](https://hex.pm/packages/glen)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glen/)

🏕️ A peaceful web framework for Gleam that targets JS.

✨ Features:

- Request & response helpers
- Helpful middleware
- File streaming
- Bring-your-own server _(optional)_
- Easily deploy on serverless platforms such as [Deno Deploy](https://deno.com/deploy)

...and other nice-to-haves!

## Installation

Install all requirements:

```sh
gleam add glen gleam_http gleam_javascript
```

Or just Glen:

```sh
gleam add glen
```

## Usage

```gleam
import gleam/javascript/promise.{type Promise}
import glen
import glen/status

pub fn main() {
  glen.serve(handle_req, 8000)
}

fn handle_req(req: glen.Request) -> Promise(glen.Response) {
  "<h1>Welcome to my webpage!</h1>
  <p>Make yourself at home 😄</p>"
  |> glen.html(status.ok)
  |> promise.resolve
}
```

Glen is heavily based off of [Wisp](https://github.com/gleam-wisp/wisp), and many of Wisp's [examples](https://github.com/gleam-wisp/wisp/tree/main/examples) can easily be ported to Glen. Glen also has an example application of its own in [./test](https://github.com/MystPi/glen/tree/main/test).

Further documentation can be found at <https://hexdocs.pm/glen>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the example application
```
