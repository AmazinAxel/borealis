import app from 'ags/gtk4/app';
import Gdk from 'gi://Gdk';
import { lockScreen, lockDisplayOff, lockThen } from '../lockscreen/lockscreen';
import { powerKeys, reboot } from '../../lib/power';
import inputControl, { type Actions } from '../../lib/inputControl';

const actions: Actions = {
  ...powerKeys,
  [Gdk.KEY_s]: () => lockThen(powerKeys[Gdk.KEY_s]),
  [Gdk.KEY_h]: () => lockThen(powerKeys[Gdk.KEY_h]),
  [Gdk.KEY_r]: reboot,
  [Gdk.KEY_l]: lockScreen,
  [Gdk.KEY_d]: lockDisplayOff,
};

const hide = () => {
  app.get_window('powermenu')?.set_visible(false);
  return true;
};

export default () => inputControl('powermenu', () => <box />, { actions, onKeyPressed: hide });
