import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import { openSocket, readBytes, type Sock } from './socket';

const address = new Gio.UnixSocketAddress({ path: GLib.getenv('SWAYSOCK') ?? '' });
const encoder = new TextEncoder();
const decoder = new TextDecoder();

const send = (sock: Sock, type: number, payload = '') => {
  const body = encoder.encode(payload);
  const msg = new Uint8Array(14 + body.length);
  msg.set(encoder.encode('i3-ipc'));
  const view = new DataView(msg.buffer);
  view.setUint32(6, body.length, true);
  view.setUint32(10, type, true);
  msg.set(body, 14);
  sock.write(msg);
};

const receive = async (sock: Sock) => {
  const header = await readBytes(sock.input, 14);
  const view = new DataView(header.buffer, header.byteOffset, 14);
  const type = view.getUint32(10, true);
  const body = await readBytes(sock.input, view.getUint32(6, true));
  return { type, json: JSON.parse(decoder.decode(body)) as unknown };
};

let sock: Sock | null = null;
let queue: Promise<unknown> = Promise.resolve();
const request = <T>(type: number, payload = '') => {
  const p = queue.then(async () => {
    try {
      sock ??= openSocket(address);
      send(sock, type, payload);
      return (await receive(sock)).json as T;
    } catch (e) {
      sock = null;
      throw e;
    }
  });
  queue = p.catch(() => { });
  return p;
};

export const swayCommand = (cmd: string) => request(0, cmd).catch(() => { });
export const swayOutputs = <T>() => request<T>(3);
export const swayTree = <T>() => request<T>(4);

const subscriptions: Sock[] = [];
export const swaySubscribe = (events: string[], cb: (event: unknown) => void) => {
  try {
    const s = openSocket(address);
    subscriptions.push(s);
    send(s, 2, JSON.stringify(events));
    const loop = () => receive(s).then(({ type, json }) => {
      loop();
      if (type & 0x80000000) cb(json);
    }).catch(() => { });
    loop();
  } catch { }
};
