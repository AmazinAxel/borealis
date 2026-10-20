import { createState } from 'ags';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GioUnix from 'gi://GioUnix';

const bus = Gio.DBus.system;
const name = 'org.freedesktop.login1';
const path = '/org/freedesktop/login1';
const manager = 'org.freedesktop.login1.Manager';

export const [ sleeping, setSleeping ] = createState(false);

bus.signal_subscribe(name, manager, 'PrepareForSleep', path, null, Gio.DBusSignalFlags.NONE,
  (_conn, _sender, _path, _iface, _signal, params) => setSleeping((params.deepUnpack() as [boolean])[0]));

let inhibitor: GioUnix.InputStream | null = null;
let wanted = false;

export const inhibitSleep = (why: string) => {
  if (wanted) return;
  wanted = true;
  bus.call_with_unix_fd_list(name, path, manager, 'Inhibit',
    new GLib.Variant('(ssss)', ['sleep', 'ags', why, 'delay']),
    null, Gio.DBusCallFlags.NONE, -1, null, null, (conn, res) => {
      try {
        const [ reply, fds ] = conn!.call_with_unix_fd_list_finish(res);
        const [ index ] = reply.deepUnpack() as [number];
        const owned = fds!.steal_fds();
        owned.forEach((fd, i) => i != index && GLib.close(fd));
        const stream = new GioUnix.InputStream({ fd: owned[index], closeFd: true });
        if (wanted) inhibitor = stream;
        else stream.close(null);
      } catch {
        wanted = false;
      }
    });
};

export const releaseSleep = () => {
  wanted = false;
  inhibitor?.close(null);
  inhibitor = null;
};
