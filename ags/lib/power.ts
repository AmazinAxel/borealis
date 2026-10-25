import { execAsync } from 'ags/process';
import Gdk from 'gi://Gdk';
import { type Actions } from './inputControl';

const systemctl = (action: string) => () => void execAsync(['systemctl', action]).catch(() => { });

export const reboot = systemctl('reboot');

export const powerKeys: Actions = {
  [Gdk.KEY_s]: systemctl('suspend'),
  [Gdk.KEY_h]: systemctl('hibernate'),
  [Gdk.KEY_q]: systemctl('poweroff'),
};
