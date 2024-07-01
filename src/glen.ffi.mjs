import * as $gleam from './gleam.mjs';
import { Readable } from 'node:stream';
import fs from 'node:fs';

export function serve(port, handler) {
  if (globalThis.Deno) {
    Deno.serve({ port }, handler);
  } else if (globalThis.Bun) {
    Bun.serve({
      port,
      fetch: handler,
    });
  } else {
    throw new Error(
      'The serve function is only available when using Deno or Bun.'
    );
  }
}

export function stream_file(path) {
  try {
    if (globalThis.Deno) {
      return new $gleam.Ok(Deno.openSync(path, { read: true }).readable);
    } else if (globalThis.Bun) {
      return new $gleam.Ok(Bun.file(path).stream());
    } else {
      return new $gleam.Ok(Readable.toWeb(fs.createReadStream(path)));
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

export function now() {
  return performance.now();
}

export function identity(x) {
  return x;
}
