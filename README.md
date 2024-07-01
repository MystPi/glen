# glen

<img src="https://raw.githubusercontent.com/MystPi/glen/main/assets/glen.png" width="150" align="right" />

[![Package Version](https://img.shields.io/hexpm/v/glen)](https://hex.pm/packages/glen)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glen/)

🏕️ A peaceful web framework for Gleam that targets JS.

✨ Features:

- Request & response helpers
- Helpful middleware
- File streaming
- Websockets
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
  glen.serve(8000, handle_req)
}

fn handle_req(req: glen.Request) -> Promise(glen.Response) {
  "<h1>Welcome to my webpage!</h1>
  <p>Make yourself at home 😄</p>"
  |> glen.html(status.ok)
  |> promise.resolve
}
```

Glen is heavily based off of [Wisp](https://github.com/gleam-wisp/wisp), and many of Wisp's [examples](https://github.com/gleam-wisp/wisp/tree/main/examples) can easily be ported to Glen. Glen also has an example application of its own in [./test](https://github.com/MystPi/glen/tree/main/test).

## Bring-your-own server

Glen's `serve` function only works on the `deno` and `bun` runtimes, but you can bring your own server so Glen can work on any runtime, such as Node.js (>= v17.0.0) or Cloudflare Workers. The `convert_request` and `convert_response` functions are here to help you with this.

> ℹ️ Glen does not support Node.js by default since Node.js does not use the web-standard `Request` and `Response` APIs in its built-in web server module.

<details>
  <summary>
    <b>Cloudflare Workers example</b>
  </summary>

> 🚨 Glen's `static` middleware will not work on the Cloudflare Workers runtime since it does not support the `node:fs` module. Everything else should work as expected.

`src/index.js`

```js
import * as glen from '../glen/glen.mjs';
import * as my_app from './my_app.mjs';

export default {
  async fetch(request, _env, _ctx) {
    const req = glen.convert_request(request);
    const response = await my_app.handle_req(req);
    const res = glen.convert_response(response);

    return res;
  },
};
```

`src/my_app.gleam`

```gleam
import gleam/javascript/promise
import glen
import glen/status

pub fn handle_req(_req) {
  "On a Cloudflare worker!"
  |> glen.html(status.ok)
  |> promise.resolve
}
```

`wrangler.toml`

```toml
main = "build/dev/javascript/my_app/index.js"
# ...
```

</details>

## Docs

Documentation can be found at <https://hexdocs.pm/glen>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the example application
```
