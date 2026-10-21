import { createState } from 'ags';
import { timeout, type Timer } from 'ags/time';
import GLib from 'gi://GLib';
import { sleeping } from './logind';

const [ now, setNow ] = createState(GLib.DateTime.new_now_local());

let tick: Timer | null = null;
const update = () => {
  tick?.cancel();
  const t = GLib.DateTime.new_now_local();
  setNow(t);
  tick = timeout((60 - t.get_second()) * 1000 - Math.floor(t.get_microsecond() / 1000), update);
};
update();
sleeping.subscribe(() => !sleeping.peek() && update());

export const formatNow = (format: string) => now((d) => d.format(format)!);
