pub type WebsocketBody

pub type WebsocketConn(event)

/// A websocket message represents an incoming message from the websocket client,
/// or a custom event sent from the server via `dispatch_event`.
pub type WebsocketMessage(event) {
  Text(String)
  Bits(BitArray)
  Event(event)
}

/// Send some text to the websocket client.
@external(javascript, "../ws_ffi.mjs", "send_text")
pub fn send_text(
  conn: WebsocketConn(event),
  text: String,
) -> Result(Nil, String)

/// Send a BitArray to the websocket client.
@external(javascript, "../ws_ffi.mjs", "send_bits")
pub fn send_bits(
  conn: WebsocketConn(event),
  bits: BitArray,
) -> Result(Nil, String)

/// Dispatch a custom event to the event handler.
@external(javascript, "../ws_ffi.mjs", "dispatch_event")
pub fn dispatch_event(conn: WebsocketConn(event), event: event) -> Nil
