import gleam/javascript/promise.{type Promise}
import gleam/http
import glen.{type Request, type Response}
import glen/status

pub fn main() {
  glen.serve(handle_req, 8000)
}

fn handle_req(req: Request) -> Promise(Response) {
  // Log all requests and responses
  use <- glen.log(req)
  // Handle potential crashes gracefully
  use <- glen.rescue_crashes
  // Serve static files from ./test/static on the path /static
  use <- glen.static(req, "static", "./test/static")

  case glen.path_segments(req) {
    [] -> index_page(req)
    ["greet"] -> greet_page(req)
    _ -> not_found(req)
  }
}

pub fn index_page(req: Request) -> Promise(Response) {
  use <- glen.require_method(req, http.Get)

  "<h1>This my webpage!</h1>
  <p>Isn't it great?</p>
  <p>This is my friend Lucy: <img src='/static/lucy.svg' width='20' /></p>
  <form action='/greet' method='post'>
    <input type='text' name='name' placeholder='What is your name?' required />
    <input type='submit' />
  </form>"
  |> glen.html(status.ok)
  |> promise.resolve
}

pub fn greet_page(req: Request) -> Promise(Response) {
  use <- glen.require_method(req, http.Post)
  use formdata <- glen.require_form(req)

  case formdata.values {
    [#("name", name)] ->
      { "<p>Lucy says: Hiya " <> glen.escape_html(name) <> "!</p>" }
      |> glen.html(status.ok)

    _ -> glen.response(status.bad_request)
  }
  |> promise.resolve
}

pub fn not_found(_req: Request) -> Promise(Response) {
  "<h1>Oops, are you lost?</h1>
  <p>This page doesn't exist.</p>"
  |> glen.html(status.not_found)
  |> promise.resolve
}
