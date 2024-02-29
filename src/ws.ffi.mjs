import * as $gleam from './gleam.mjs';
import * as $ws from './glen/ws.mjs';

class WebsocketConn {
  constructor(socket, on_open, on_close, on_event) {
    // We want the socket to recieve ArrayBuffers, not Blobs
    socket.binaryType = 'arraybuffer';

    this.socket = socket;
    this.on_event = on_event;

    socket.onopen = () => {
      this.state = on_open(this);
    };

    socket.onclose = () => {
      on_close(this.state);
    };

    socket.onmessage = (e) => {
      let msg;

      if (e.data instanceof ArrayBuffer) {
        msg = new $ws.Bits(new Uint8Array(e.data));
      } else {
        msg = new $ws.Text(e.data);
      }

      this.state = on_event(this, this.state, msg);
    };
  }

  dispatch_event(event) {
    this.state = this.on_event(this, this.state, new $ws.Event(event));
  }
}

export function upgrade(req, on_open, on_close, on_event) {
  // Since req is a Glen request, the body is the original JS Request object
  const { socket, response } = Deno.upgradeWebSocket(req.body);

  const conn = new WebsocketConn(socket, on_open, on_close, on_event);

  return [response, conn];
}

export function send(conn, msg) {
  try {
    conn.socket.send(msg);
    return new $gleam.Ok();
  } catch (e) {
    return new $gleam.Error(e.message);
  }
}

export const send_text = send;

export function send_bits(bits) {
  return send(bits.buffer);
}

export function dispatch_event(conn, event) {
  conn.dispatch_event(event);
}
