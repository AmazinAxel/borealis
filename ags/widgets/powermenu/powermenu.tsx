import app from 'ags/gtk4/app';
import Gdk from 'gi://Gdk';
import { Gtk } from 'ags/gtk4';
import { lockScreen } from '../lockscreen/lockscreen';
import { suspend, hibernate, poweroff, reboot } from '../../lib/power';
import inputControl from '../../lib/inputControl';

const actions: Record<number, () => void> = {
  [Gdk.KEY_s]: suspend,
  [Gdk.KEY_h]: hibernate,
  [Gdk.KEY_q]: poweroff,
  [Gdk.KEY_r]: reboot,
  [Gdk.KEY_l]: lockScreen,
};

const handleKeys = (_ctrl: Gtk.EventControllerKey, key: number) => {
  app.get_window('powermenu')?.hide();
  actions[Gdk.keyval_to_lower(key)]?.();
  return true;
};

export default () => inputControl('powermenu', () => <box />, { onKeyPressed: handleKeys });
