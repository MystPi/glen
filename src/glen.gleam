//// 🏕️ A peaceful web framework that targets JS.
////
//// Other packages you will need:
//// - [`gleam_http`](https://hexdocs.pm/gleam_http/) — everything `Request` and
//// `Response` related
//// - [`gleam_javascript`](https://hexdocs.pm/gleam_javascript/) — provides tools
//// for working with JavaScript promises.

import gleam/io
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/option
import gleam/dynamic.{type Dynamic}
import gleam/http
import gleam/http/request.{type Request as HttpRequest}
import gleam/http/response.{
  type Response as HttpResponse, Response as HttpResponse,
}
import gleam/javascript/promise.{type Promise}
import conversation.{type JsReadableStream, type JsRequest, type JsResponse}
import marceau
import gleam_community/ansi
import glen/status

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
}

/// An outgoing response.
pub type Response =
  HttpResponse(ResponseBody)

/// A JavaScript request handler.
pub type JsHandler =
  fn(JsRequest) -> Promise(JsResponse)

/// A request handler.
///
/// # Examples
///
/// ```
/// fn my_serve(handler: glen.Handler, port: Int) -> Nil {
///   io.println("Starting server...")
///   glen.serve(handler, port)
/// }
/// ```
pub type Handler =
  fn(Request) -> Promise(Response)

// SERVER ----------------------------------------------------------------------

@external(javascript, "./ffi.mjs", "deno_serve")
fn deno_serve(handler: JsHandler, port: Int) -> Nil

/// Start a server using `Deno.serve`.
///
/// > ℹ️ Only works when using the `deno` runtime. Try [`custom_serve`](#custom_serve)
/// for other runtimes such as Node.js.
///
/// # Examples
///
/// ```
/// fn(_req) {
///   "Hello, world!"
///   |> glen.text(status.ok)
///   |> promise.resolve
/// }
/// |> glen.serve(8000)
/// ```
pub fn serve(handler: Handler, port: Int) -> Nil {
  custom_serve(handler, deno_serve, port)
}

/// Start a server using a custom JavaScript server.
///
/// > ℹ️ The [`serve`](#serve) function is recommended when using the `deno` runtime.
///
/// # Examples
///
/// ```
/// @external(javascript, "./serve.mjs", "serve")
/// fn my_serve(handler: glen.JsHandler) -> Nil
///
/// fn(_req) {
///   "Hello, world!"
///   |> glen.text(status.ok)
///   |> promise.resolve
/// }
/// |> glen.custom_serve(my_serve, 8000)
/// ```
pub fn custom_serve(
  handler: Handler,
  server: fn(JsHandler, Int) -> Nil,
  port: Int,
) -> Nil {
  fn(req) {
    conversation.translate_request(req)
    |> handler
    |> promise.map(to_conversation_response)
    |> promise.map(conversation.translate_response)
  }
  |> server(port)
}

fn to_conversation_response(
  res: Response,
) -> HttpResponse(conversation.ResponseBody) {
  let #(body, status) = case res.body {
    Text(text) -> #(conversation.Text(text), res.status)
    Bits(bits) -> #(conversation.Bits(bits), res.status)
    Empty -> #(conversation.Bits(<<>>), res.status)
    File(path) -> file_stream(path, res.status)
  }

  HttpResponse(status, res.headers, body)
}

@external(javascript, "./ffi.mjs", "stream_file")
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
    |> string.split(".")
    |> list.last
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
        conversation.ParseError(_) | conversation.ReadError(_) ->
          response(status.bad_request)
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

fn join_path(a: String, b: String) -> String {
  let b = remove_preceeding_slashes(b)
  case string.ends_with(a, "/") {
    True -> a <> b
    False -> a <> "/" <> b
  }
}

@external(javascript, "./ffi.mjs", "file_exists")
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
        |> string.replace("..", "")
        |> join_path(directory, _)

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
  use res <- promise.await(next())
  log_response(res)
  promise.resolve(res)
}

@external(javascript, "./ffi.mjs", "rescue")
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

@external(javascript, "./ffi.mjs", "get_timestamp")
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

  let url =
    http.scheme_to_string(req.scheme)
    <> "://"
    <> req.host
    <> req.path
    <> get_query_string(req)

  io.println(ansi.blue("[req] ") <> method <> " " <> url)
}

fn log_response(res: Response) -> Nil {
  let color = case status.classify(res.status) {
    status.Successful -> ansi.green
    status.ServerError -> ansi.red
    _ -> ansi.yellow
  }

  io.println(color("[res]") <> " ~> " <> int.to_string(res.status))
}

fn log_error(message: String) -> Nil {
  io.println(ansi.red("[err] ") <> ansi.italic(message))
}
