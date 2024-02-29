//// Types and functions for working with websockets. Use the `glen.websocket`
//// function to start a websocket connection from a request handler.

pub type WebsocketBody

pub type WebsocketConn(event)

/// A websocket message represents an incoming message from the websocket client,
/// or a custom event sent from the server via `dispatch_event`.
pub type WebsocketMessage(event) {
  /// Recieved a text message
  Text(String)
  /// Recieved a BitArray message
  Bits(BitArray)
  /// Recieved a custom event
  Event(event)
}

/// Send text to the websocket client.
@external(javascript, "../ws.ffi.mjs", "send_text")
pub fn send_text(
  conn: WebsocketConn(event),
  text: String,
) -> Result(Nil, String)

/// Send a BitArray to the websocket client.
@external(javascript, "../ws.ffi.mjs", "send_bits")
pub fn send_bits(
  conn: WebsocketConn(event),
  bits: BitArray,
) -> Result(Nil, String)

/// Dispatch a custom event to the event handler. A custom event allows you to
/// call the websocket's `on_event` function from the server-side with a message
/// of `ws.Event(a)`.
@external(javascript, "../ws.ffi.mjs", "dispatch_event")
pub fn dispatch_event(conn: WebsocketConn(event), event: event) -> Nil
