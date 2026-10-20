import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

export const bus = Gio.DBus.system;
export const iwdBus = 'net.connman.iwd';
export const deviceInterface = 'net.connman.iwd.Device';
export const stationInterface = 'net.connman.iwd.Station';
export const networkInterface = 'net.connman.iwd.Network';

export type IwdObjects = Record<string, Record<string, Record<string, unknown>>>;

export const iwdCall = <T = unknown[]>(path: string, iface: string, method: string, params: GLib.Variant | null = null) =>
  new Promise<T>((resolve, reject) => bus.call(iwdBus, path, iface, method, params, null, Gio.DBusCallFlags.NONE, -1, null,
    (conn, res) => {
      try {
        resolve(conn!.call_finish(res).recursiveUnpack() as T);
      } catch (e) {
        reject(e);
      }
    }));

export const getObjects = () => iwdCall<[IwdObjects]>('/', 'org.freedesktop.DBus.ObjectManager', 'GetManagedObjects')
  .then(([ objects ]) => objects);

export const onPropertiesChanged = (cb: (path: string, iface: string, changed: Record<string, unknown>) => void) =>
  bus.signal_subscribe(iwdBus, 'org.freedesktop.DBus.Properties', 'PropertiesChanged', null, null, Gio.DBusSignalFlags.NONE,
    (_conn, _sender, path, _iface, _signal, params) => {
      const [ iface, changed ] = params.recursiveUnpack() as [string, Record<string, unknown>];
      cb(path, iface, changed);
    });
