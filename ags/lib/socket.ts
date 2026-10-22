import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

export type Sock = { conn: Gio.SocketConnection, input: Gio.DataInputStream, write: (data: Uint8Array) => void };

export const openSocket = (address: Gio.SocketConnectable): Sock => {
  const conn = new Gio.SocketClient().connect(address, null);
  const input = new Gio.DataInputStream({
    baseStream: conn.get_input_stream(),
    byteOrder: Gio.DataStreamByteOrder.LITTLE_ENDIAN,
  });
  const out = conn.get_output_stream();
  return { conn, input, write: (data) => void out.write_all(data, null) };
};

export const readBytes = (input: Gio.BufferedInputStream, n: number) => new Promise<Uint8Array>((resolve, reject) => {
  if (input.get_buffer_size() < n) input.set_buffer_size(n);
  const step = () => {
    if (input.get_available() >= n) return resolve(input.read_bytes(n, null).toArray());
    input.fill_async(-1, GLib.PRIORITY_DEFAULT, null, (_, res) => {
      try {
        if (input.fill_finish(res) > 0) step();
        else reject(new Error('closed'));
      } catch (e) {
        reject(e);
      }
    });
  };
  step();
});

export const readLine = (input: Gio.DataInputStream) => new Promise<string>((resolve, reject) =>
  input.read_line_async(GLib.PRIORITY_DEFAULT, null, (_, res) => {
    try {
      const [ line ] = input.read_line_finish_utf8(res);
      if (line === null) reject(new Error('closed'));
      else resolve(line);
    } catch (e) {
      reject(e);
    }
  }));
