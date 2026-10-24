import app from 'ags/gtk4/app';
import Gdk from 'gi://Gdk';
import { Gtk } from 'ags/gtk4';
import { lockScreen, lockDisplayOff, lockThen } from '../lockscreen/lockscreen';
import { powerKeys, reboot } from '../../lib/power';
import inputControl from '../../lib/inputControl';

const actions: Record<number, () => void> = {
  ...powerKeys,
  [Gdk.KEY_s]: () => lockThen(powerKeys[Gdk.KEY_s]),
  [Gdk.KEY_h]: () => lockThen(powerKeys[Gdk.KEY_h]),
  [Gdk.KEY_r]: reboot,
  [Gdk.KEY_l]: lockScreen,
  [Gdk.KEY_d]: lockDisplayOff,
};

const handleKeys = (_ctrl: Gtk.EventControllerKey, key: number) => {
  const action = actions[Gdk.keyval_to_lower(key)];
  if (action) action();
  else app.get_window('powermenu')?.set_visible(false);
  return true;
};

export default () => inputControl('powermenu', () => <box />, { onKeyPressed: handleKeys });
