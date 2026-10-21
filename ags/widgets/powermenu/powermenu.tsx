import app from 'ags/gtk4/app';
import Gdk from 'gi://Gdk';
import { Gtk } from 'ags/gtk4';
import { lockScreen, lockDisplayOff } from '../lockscreen/lockscreen';
import { powerKeys, reboot } from '../../lib/power';
import inputControl from '../../lib/inputControl';

const actions: Record<number, () => void> = {
  ...powerKeys,
  [Gdk.KEY_r]: reboot,
  [Gdk.KEY_l]: lockScreen,
  [Gdk.KEY_d]: lockDisplayOff,
};

const handleKeys = (_ctrl: Gtk.EventControllerKey, key: number) => {
  app.get_window('powermenu')?.hide();
  actions[Gdk.keyval_to_lower(key)]?.();
  return true;
};

export default () => inputControl('powermenu', () => <box />, { onKeyPressed: handleKeys });
