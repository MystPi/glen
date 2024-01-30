import * as $gleam from './gleam.mjs';
import fs from 'node:fs';
import { createReadableStreamFromReadable } from './stream.mjs';

export function deno_serve(handler, port) {
  Deno.serve({ port }, handler);
}

export function stream_file(path) {
  try {
    if (globalThis.Deno) {
      return new $gleam.Ok(Deno.openSync(path, { read: true }).readable);
    } else {
      const stream = fs.createReadStream(path);
      const readableStream = createReadableStreamFromReadable(stream);
      return new $gleam.Ok(readableStream);
    }
  } catch (_e) {
    return new $gleam.Error();
  }
}

export function file_exists(path) {
  return fs.existsSync(path);
}

export function get_timestamp() {
  return new Date().toISOString();
}

export async function rescue(handler) {
  try {
    return new $gleam.Ok(await handler());
  } catch (e) {
    return new $gleam.Error(e.message);
  }
}