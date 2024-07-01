//// 🏕️ A peaceful web framework that targets JS.
////
//// Other packages you will need:
//// - [`gleam_http`](https://hexdocs.pm/gleam_http/) — everything `Request` and
//// `Response` related
//// - [`gleam_javascript`](https://hexdocs.pm/gleam_javascript/) — provides tools
//// for working with JavaScript promises.

import conversation
import filepath
import gleam/dynamic.{type Dynamic}
import gleam/float
import gleam/http
import gleam/http/request.{type Request as HttpRequest}
import gleam/http/response.{
  type Response as HttpResponse, Response as HttpResponse,
}
import gleam/int
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam_community/ansi
import glen/status
import glen/ws
import marceau

// TYPES -----------------------------------------------------------------------

/// An incoming request's body.
pub type RequestBody =
  conversation.RequestBody

/// An incoming request.
pub type Request =
  HttpRequest(RequestBody)

/// An outgoing response's body.
pub type ResponseBody {
  /// A text body.
  Text(String)
  /// A file body. The file will be streamed and not read into memory, so it is
  /// okay to send files of any size. If the file cannot be accessed, an empty
  /// response with a 500 status code (internal server error) will be returned.
  File(path: String)
  /// A `BitArray` body.
  Bits(BitArray)
  /// An empty body, equivalent to `Bits(<<>>)`.
  Empty
  /// A websocket response body.
  Websocket(ws.WebsocketBody)
}

/// An outgoing response.
pub type Response =
  HttpResponse(ResponseBody)

/// A JavaScript request handler.
pub type JsHandler =
  fn(JsRequest) -> Promise(JsResponse)

/// A standard JavaScript [`Request`](https://developer.mozilla.org/en-US/docs/Web/API/Request).
pub type JsRequest =
  conversation.JsRequest

/// A standard JavaScript [`Response`](https://developer.mozilla.org/en-US/docs/Web/API/Response).
pub type JsResponse =
  conversation.JsResponse

/// A standard JavaScript [`ReadableStream`](https://developer.mozilla.org/en-US/docs/Web/API/ReadableStream).
pub type JsReadableStream =
  conversation.JsReadableStream

/// A request handler.
///
/// # Examples
///
/// ```
/// fn my_serve(port: Int, handler: glen.Handler) -> Nil {
///   io.println("Starting server...")
///   glen.serve(port, handler)
/// }
/// ```
pub type Handler =
  fn(Request) -> Promise(Response)

// SERVER ----------------------------------------------------------------------

@external(javascript, "./glen.ffi.mjs", "serve")
fn js_serve(port: Int, handler: JsHandler) -> Nil

/// Start a server using `Deno.serve` or `Bun.serve`.
///
/// > ℹ️ Only works when using the `deno` or `bun` runtime. See the readme for more
/// info.
///
/// # Examples
///
/// ```
/// glen.serve(8000, fn(_req) {
///   "Hello, world!"
///   |> glen.text(status.ok)
///   |> promise.resolve
/// })
/// ```
pub fn serve(port: Int, handler: Handler) -> Nil {
  use req <- js_serve(port)

  convert_request(req)
  |> handler
  |> promise.map(convert_response)
}

/// Convert a JavaScript request into a Glen request.
pub fn convert_request(req: conversation.JsRequest) -> Request {
  conversation.translate_request(req)
}

/// Convert a Glen response into a JavaScript response.
pub fn convert_response(res: Response) -> conversation.JsResponse {
  let make_res = HttpResponse(res.status, res.headers, _)

  case res.body {
    Text(text) ->
      make_res(conversation.Text(text))
      |> conversation.translate_response

    Bits(bits) ->
      make_res(conversation.Bits(bits))
      |> conversation.translate_response

    Empty ->
      make_res(conversation.Bits(<<>>))
      |> conversation.translate_response

    File(path) -> {
      let #(body, status) = file_stream(path, res.status)
      HttpResponse(status, res.headers, body)
      |> conversation.translate_response
    }

    Websocket(w) -> ws_body_to_response(w)
  }
}

@external(javascript, "./glen.ffi.mjs", "identity")
fn ws_body_to_response(body: ws.WebsocketBody) -> JsResponse

@external(javascript, "./glen.ffi.mjs", "stream_file")
fn do_file_stream(path: String) -> Result(JsReadableStream, Nil)

fn file_stream(path: String, status: Int) -> #(conversation.ResponseBody, Int) {
  case do_file_stream(path) {
    Ok(stream) -> #(conversation.Stream(stream), status)
    Error(_) -> {
      log_error("Unable to access " <> path)
      #(conversation.Bits(<<>>), status.internal_server_error)
    }
  }
}

// RESPONSE HELPERS ------------------------------------------------------------

/// Set the body of a response.
///
/// > ℹ️ This function is re-exported from `gleam_http`.
pub const set_body: fn(Response, ResponseBody) -> Response = response.set_body

/// Set the header with the given value under the given header key.
///
/// If the response already has that key, it is replaced.
///
/// > ℹ️ This function is re-exported from `gleam_http`.
pub const set_header: fn(Response, String, String) -> Response = response.set_header

/// Set the body of a response to text.
pub fn text_body(res: Response, text: String) -> Response {
  set_body(res, Text(text))
}

/// Set the body of a response to HTML.
pub fn html_body(res: Response, html: String) -> Response {
  res
  |> set_body(Text(html))
  |> set_header("content-type", "text/html")
}

/// Set the body of a response to JSON.
pub fn json_body(res: Response, json: String) -> Response {
  res
  |> set_body(Text(json))
  |> set_header("content-type", "application/json")
}

/// Set the body of a response to a `BitArray`.
pub fn bit_array_body(res: Response, bits: BitArray) -> Response {
  set_body(res, Bits(bits))
}

/// Set the body of a response to a file stream. The `content-type` header
/// will be automatically set based on the file's extension.
pub fn file_body(res: Response, path: String) -> Response {
  let content_type =
    path
    |> filepath.extension
    |> result.unwrap("")
    |> string.lowercase
    |> marceau.extension_to_mime_type

  res
  |> set_body(File(path))
  |> set_header("content-type", content_type)
}

/// Create a response with the given status code and an empty body.
pub fn response(status: Int) -> Response {
  HttpResponse(status, [], Empty)
}

/// Create a response with a text body.
pub fn text(text: String, status: Int) -> Response {
  response(status)
  |> text_body(text)
}

/// Create a response with an HTML body.
pub fn html(html: String, status: Int) -> Response {
  response(status)
  |> html_body(html)
}

/// Create a response with a JSON body.
pub fn json(json: String, status: Int) -> Response {
  response(status)
  |> json_body(json)
}

/// Create a response with a file stream as the body. The `content-type` header
/// will be automatically set based on the file's extension.
pub fn file(path: String, status: Int) -> Response {
  response(status)
  |> file_body(path)
}

/// Redirect the client to a URL with the given status. The status should be
/// in the 3xx range (such as `303: See Other` or `307: Temporary Redirect`).
pub fn redirect(url: String, status: Int) -> Response {
  response(status)
  |> set_header("location", url)
}

/// Create a response with a status of 405 (method not allowed). The `allowed`
/// header will be set to the given allowed methods.
pub fn method_not_allowed(allowed: List(http.Method)) -> Response {
  let allowed =
    allowed
    |> list.map(http.method_to_string)
    |> string.join(", ")
    |> string.uppercase

  response(status.method_not_allowed)
  |> set_header("allowed", allowed)
}

/// Create a response with a status of 415 (unsupported media type). The `accept`
/// header will be set to the given supported content types.
pub fn unsupported_media_type(supported: List(String)) -> Response {
  response(status.unsupported_media_type)
  |> set_header("accept", string.join(supported, ", "))
}

// REQUEST HELPERS -------------------------------------------------------------

/// Return the non-empty segments of a request path.
///
/// > ℹ️ This function is re-exported from `gleam_http`.
///
/// # Examples
///
/// ```
/// case glen.path_segments(req) {
///   [] -> index_page()
///   ["about"] -> about_page()
///   ["greet", name] -> greet_page(name)
///   _ -> not_found_page()
/// }
/// ```
pub const path_segments: fn(Request) -> List(String) = request.path_segments

/// Read a request body as text.
pub fn read_text_body(
  req: Request,
) -> Promise(Result(String, conversation.ReadError)) {
  conversation.read_text(req.body)
}

/// Read a request body as JSON.
pub fn read_json_body(
  req: Request,
) -> Promise(Result(Dynamic, conversation.ReadError)) {
  conversation.read_json(req.body)
}

/// Read a request body as a `BitArray`.
pub fn read_body_bits(
  req: Request,
) -> Promise(Result(BitArray, conversation.ReadError)) {
  conversation.read_bits(req.body)
}

/// Read a request body as [`FormData`](https://hexdocs.pm/conversation/conversation.html#FormData).
pub fn read_form_body(
  req: Request,
) -> Promise(Result(conversation.FormData, conversation.ReadError)) {
  conversation.read_form(req.body)
}

/// Get the query parameters from a request. Parameters are not predictably
/// ordered, so you should not pattern match on them. Instead, use the
/// [`key_find`](https://hexdocs.pm/gleam_stdlib/gleam/list.html#key_find)
/// function from `gleam/list` to access parameters.
pub fn get_query(req: Request) -> List(#(String, String)) {
  req
  |> request.get_query
  |> result.unwrap([])
}

// MIDDLEWARE ------------------------------------------------------------------

/// Middleware function for requiring the request to be of a certain HTTP method.
/// Returns the same as [`method_not_allowed`](#method_not_allowed) if the method
/// does not meet the requirement.
///
/// # Examples
///
/// ```
/// fn handle_req(req) {
///   use <- glen.require_method(req, http.Get)
///   // ...only GET requests are allowed...
/// }
/// ```
pub fn require_method(
  req: Request,
  method: http.Method,
  next: fn() -> Promise(Response),
) -> Promise(Response) {
  case req.method == method {
    True -> next()
    False ->
      method_not_allowed([method])
      |> promise.resolve
  }
}

/// Middleware function for requiring the request to have a `content-type` header
/// with a specific content type. Returns the same as
/// [`unsupported_media_type`](#unsupported_media_type) if the header is missing
/// or does not meet the requirement.
///
/// # Examples
///
/// ```
/// fn handle_req(req) {
///   use <- glen.require_content_type(req, "text/html")
///   // ...the request's content-type must be text/html...
/// }
/// ```
pub fn require_content_type(
  req: Request,
  required: String,
  next: fn() -> Promise(Response),
) -> Promise(Response) {
  case list.key_find(req.headers, "content-type") {
    Ok(content_type) if content_type == required -> next()
    _ ->
      unsupported_media_type([required])
      |> promise.resolve
  }
}

fn handle_read_errors(
  result: Result(a, conversation.ReadError),
  next: fn(a) -> Promise(Response),
) -> Promise(Response) {
  case result {
    Ok(value) -> next(value)
    Error(error) ->
      case error {
        conversation.ParseError(_)
        | conversation.ReadError(_) -> response(status.bad_request)
        conversation.AlreadyRead -> {
          log_error("Request body has already been read")
          response(status.internal_server_error)
        }
      }
      |> promise.resolve
  }
}

/// Middleware function that reads a request body as a string.
///
/// # Examples
///
/// ```
/// fn handle_req(req) {
///   use string_body <- glen.require_string_body(req)
///
///   "You gave me: " <> glen.escape_html(string_body)
///   |> glen.html(status.ok)
///   |> promise.resolve
/// }
/// ```
pub fn require_string_body(
  req: Request,
  next: fn(String) -> Promise(Response),
) -> Promise(Response) {
  use body <- promise.await(read_text_body(req))
  handle_read_errors(body, next)
}

/// Middleware function that reads a request body as a `BitArray`.
///
/// # Examples
///
/// ```
/// fn handle_req(req) {
///   use bits <- glen.require_bit_array_body(req)
///
///   "Look at all the bits! " <> string.inspect(bits)
///   |> glen.html(status.ok)
///   |> promise.resolve
/// }
/// ```
pub fn require_bit_array_body(
  req: Request,
  next: fn(BitArray) -> Promise(Response),
) -> Promise(Response) {
  use body <- promise.await(read_body_bits(req))
  handle_read_errors(body, next)
}

/// Middleware function for requiring the request body to be JSON with a
/// `content-type` of `application/json`.
///
/// # Examples
///
/// ```
/// fn handle_req(req) {
///   use json <- glen.require_json(req)
///
///   case my_decoder(json) {
///     Ok(decoded) -> decoded.foo |> glen.text(status.ok)
///     Error(_) -> glen.response(status.bad_request)
///   }
///   |> promise.resolve
/// }
/// ```
pub fn require_json(
  req: Request,
  next: fn(Dynamic) -> Promise(Response),
) -> Promise(Response) {
  use <- require_content_type(req, "application/json")
  use body <- promise.await(read_json_body(req))
  handle_read_errors(body, next)
}

/// Middleware for requiring the request body to be a form with a `content-type`
/// of either `application/x-www-form-urlencoded` or `multipart/form-data`.
///
/// Formdata values are sorted alphabetically so they can be pattern matched on.
///
/// # Examples
///
/// ```
/// fn handle_req(req) {
///   use formdata <- glen.require_form(req)
///
///   case formdata.values {
///     [#("name", name)] -> greet(name)
///     _ -> glen.response(status.bad_request)
///   }
///   |> promise.resolve
/// }
/// ```
pub fn require_form(
  req: Request,
  next: fn(conversation.FormData) -> Promise(Response),
) -> Promise(Response) {
  case list.key_find(req.headers, "content-type") {
    Ok("application/x-www-form-urlencoded")
    | Ok("application/x-www-form-urlencoded;" <> _)
    | Ok("multipart/form-data")
    | Ok("multipart/form-data;" <> _) -> {
      use body <- promise.await(read_form_body(req))
      handle_read_errors(body, next)
    }

    _ ->
      unsupported_media_type([
        "application/x-www-form-urlencoded", "multipart/form-data",
      ])
      |> promise.resolve
  }
}

fn remove_preceeding_slashes(path: String) -> String {
  case path {
    "/" <> rest -> remove_preceeding_slashes(rest)
    _ -> path
  }
}

@external(javascript, "./glen.ffi.mjs", "file_exists")
fn file_exists(path: String) -> Bool

/// Middleware for serving up static files from a directory under a path prefix.
///
/// # Examples
///
/// ```
/// fn handle_req(req) {
///   use <- glen.static(req, "static", "./somedir/static")
///
///   "<img src='/static/image.png'/>" |> glen.html(status.ok) |> promise.resolve
/// }
/// ```
pub fn static(
  req: Request,
  prefix: String,
  directory: String,
  next: fn() -> Promise(Response),
) -> Promise(Response) {
  let prefix = remove_preceeding_slashes(prefix)
  let path = remove_preceeding_slashes(req.path)

  case req.method, string.starts_with(path, prefix) {
    http.Get, True -> {
      let path =
        path
        |> string.drop_left(string.length(prefix))
        |> filepath.expand
        |> result.unwrap("")
        |> filepath.join(directory, _)

      case file_exists(path) {
        False -> next()
        True ->
          file(path, status.ok)
          |> promise.resolve
      }
    }
    _, _ -> next()
  }
}

@external(javascript, "./glen.ffi.mjs", "now")
fn now() -> Float

/// Middleware function for logging requests and responses.
///
/// # Examples
///
/// ```
/// fn handle_req(req) {
///   use <- glen.log(req)
///   // ...requests and responses are now logged...
/// }
/// ```
pub fn log(req: Request, next: fn() -> Promise(Response)) -> Promise(Response) {
  log_timestamp()
  log_request(req)

  let before = now()
  use res <- promise.await(next())
  let after = now()

  let time = after -. before

  log_response(res, time)

  promise.resolve(res)
}

@external(javascript, "./glen.ffi.mjs", "rescue")
fn do_rescue(
  handler: fn() -> Promise(Response),
) -> Promise(Result(Response, String))

/// Middleware function that rescues any crashes with an empty response and a
/// status of 500 (internal server error).
///
/// Gleam code should never crash under normal circumstances, but it's always good
/// to be prepared.
///
/// # Examples
///
/// ```
/// fn handle_req(req) {
///   use <- glen.rescue_crashes
///   // ...crashes are now handled gracefully...
/// }
/// ```
pub fn rescue_crashes(handler: fn() -> Promise(Response)) -> Promise(Response) {
  use result <- promise.await(do_rescue(handler))

  case result {
    Ok(response) ->
      response
      |> promise.resolve
    Error(message) -> {
      log_error("Handler crashed: " <> message)
      response(status.internal_server_error)
      |> promise.resolve
    }
  }
}

// WEBSOCKETS ------------------------------------------------------------------

@external(javascript, "./ws.ffi.mjs", "upgrade")
fn upgrade(
  req: Request,
  on_open: fn(ws.WebsocketConn(event)) -> state,
  on_close: fn(state) -> Nil,
  on_event: fn(ws.WebsocketConn(event), state, ws.WebsocketMessage(event)) ->
    state,
) -> #(ws.WebsocketBody, ws.WebsocketConn(event))

/// Upgrade a request to become a websocket. If the request does not have an
/// `upgrade` header set to `websocket`, a response of 426 (upgrade required) will
/// be returned.
///
/// - `on_open` gets called when a client starts a websocket connection.
/// - `on_close` is called when the connection in closed.
/// - `on_event` gets called when the websocket recieves an event or message.
///
/// > ℹ️ Websockets are currently only supported when using the `deno` runtime.
///
/// # Examples
///
/// See [this](https://github.com/MystPi/glen/blob/main/test/glen_test.gleam)
/// for a more detailed example of websockets.
///
/// ```
/// fn handle_req(req) {
///   use _conn <- glen.websocket(
///     req,
///     on_open: on_open,
///     on_close: on_close,
///     on_event: on_event,
///   )
///   Nil
/// }
///
/// fn on_open(conn) {
///   // ...
/// }
///
/// fn on_close(state) {
///   // ...
/// }
///
/// fn on_event(conn, state, msg) {
///   // ...
/// }
/// ```
pub fn websocket(
  req: Request,
  on_open on_open: fn(ws.WebsocketConn(event)) -> state,
  on_close on_close: fn(state) -> Nil,
  on_event on_event: fn(
    ws.WebsocketConn(event),
    state,
    ws.WebsocketMessage(event),
  ) ->
    state,
  with_conn do: fn(ws.WebsocketConn(event)) -> Nil,
) -> Promise(Response) {
  case list.key_find(req.headers, "upgrade") {
    Ok("websocket") -> {
      let #(body, conn) = upgrade(req, on_open, on_close, on_event)

      do(conn)

      // Create a "fake" response with the real response as the body
      response(0)
      |> set_body(Websocket(body))
      |> promise.resolve
    }
    _ ->
      response(status.upgrade_required)
      |> set_header("upgrade", "websocket")
      |> promise.resolve
  }
}

// UTILITIES -------------------------------------------------------------------

/// Escape a string so it can be included inside of HTML safely. You should run
/// this function on all user input being included in HTML to prevent possible
/// [XSS attacks](https://en.wikipedia.org/wiki/Cross-site_scripting).
pub fn escape_html(string: String) -> String {
  string
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("&", "&amp;")
}

// LOGGING ---------------------------------------------------------------------

@external(javascript, "./glen.ffi.mjs", "get_timestamp")
fn get_timestamp() -> String

fn log_timestamp() -> Nil {
  { "[" <> get_timestamp() <> "]" }
  |> ansi.dim
  |> io.println
}

fn get_query_string(req: Request) -> String {
  case req.query {
    option.None -> ""
    option.Some(q) -> "?" <> q
  }
}

fn log_request(req: Request) -> Nil {
  let method =
    req.method
    |> http.method_to_string
    |> string.uppercase

  let scheme = case list.key_find(req.headers, "upgrade") {
    Ok("websocket") -> "ws"
    _ -> http.scheme_to_string(req.scheme)
  }

  let url = scheme <> "://" <> req.host <> req.path <> get_query_string(req)

  io.println(ansi.blue("[req] ") <> method <> " " <> url)
}

fn log_response(res: Response, time: Float) -> Nil {
  let color = case status.classify(res.status) {
    status.Successful -> ansi.green
    status.Redirection | status.Informational -> ansi.cyan
    status.ClientError -> ansi.yellow
    status.ServerError -> ansi.red
  }

  let time =
    time
    |> round
    |> float.to_string

  let info = case res.status == 0 {
    True -> " websocket started"
    False -> " ~> " <> int.to_string(res.status)
  }

  io.println(color("[res]") <> info <> ansi.italic(" (" <> time <> "ms)"))
}

/// Rounds a Float to 3 decimal places
fn round(f: Float) -> Float {
  int.to_float(float.round(f *. 1000.0)) /. 1000.0
}

fn log_error(message: String) -> Nil {
  io.println(ansi.red("[err] ") <> ansi.italic(message))
}
