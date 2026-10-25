import GLib from 'gi://GLib';

const idle = (fn: () => void, priority = GLib.PRIORITY_HIGH_IDLE) =>
  GLib.idle_add(priority, () => {
    fn();
    return GLib.SOURCE_REMOVE;
  });
export default idle;

export const idleOnce = (fn: () => void) => {
  let queued = false;
  return () => {
    if (queued) return;
    queued = true;
    idle(() => {
      queued = false;
      fn();
    });
  };
};
