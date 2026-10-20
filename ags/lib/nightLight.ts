import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

const busName = 'rs.wl-gammarelay';
let enabled = true;

const apply = () => Gio.DBus.session.call(
  busName, '/', 'org.freedesktop.DBus.Properties', 'Set',
  new GLib.Variant('(ssv)', ['rs.wl.gammarelay', 'Temperature', new GLib.Variant('q', enabled ? 3500 : 6500)]),
  null, Gio.DBusCallFlags.NONE, -1, null, (conn, res) => {
    try {
      conn!.call_finish(res);
    } catch { }
  },
);

Gio.bus_watch_name(Gio.BusType.SESSION, busName, Gio.BusNameWatcherFlags.NONE, apply, null);

export const toggleNightLight = () => {
  enabled = !enabled;
  apply();
};
