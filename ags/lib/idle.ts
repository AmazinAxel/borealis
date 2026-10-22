import GLib from 'gi://GLib';

export default (fn: () => void, priority = GLib.PRIORITY_HIGH_IDLE) =>
  GLib.idle_add(priority, () => {
    fn();
    return GLib.SOURCE_REMOVE;
  });
