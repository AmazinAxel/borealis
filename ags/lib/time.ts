import { createState } from 'ags';
import GLib from 'gi://GLib';
import { sleeping } from './logind';

const [ now, setNow ] = createState(GLib.DateTime.new_now_local());

let tick = 0;
const update = () => {
  if (tick) GLib.source_remove(tick);
  const t = GLib.DateTime.new_now_local();
  setNow(t);
  const msToNextMinute = (60 - t.get_second()) * 1000 - Math.floor(t.get_microsecond() / 1000);
  tick = GLib.timeout_add(GLib.PRIORITY_DEFAULT, msToNextMinute, () => {
    tick = 0;
    update();
    return GLib.SOURCE_REMOVE;
  });
};
update();
sleeping.subscribe(() => !sleeping.peek() && update());

export const formatNow = (format: string) => now((d) => d.format(format)!);
