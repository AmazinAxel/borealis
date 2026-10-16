import app from 'ags/gtk4/app'
import Gdk from 'gi://Gdk';
import { execAsync } from 'ags/process';
import { lockScreen } from '../lockscreen/lockscreen';
import inputControl from '../../lib/inputControl';

const handleKeys = (_ctrl: any, key: number) => {
   app.get_window('powermenu')?.hide();
   switch (Gdk.keyval_to_lower(key)) {
      case Gdk.KEY_s: // sleep
         lockScreen();
         execAsync('systemctl suspend');
         break;
      case Gdk.KEY_h:
         execAsync('systemctl hibernate');
         break;
      case Gdk.KEY_q: // power off
         execAsync('systemctl poweroff')
         break;
      case Gdk.KEY_l:
         lockScreen();
         break;
      case Gdk.KEY_r:
         execAsync('systemctl reboot');
         break;
   };
};

export default () => inputControl('powermenu', () => <box/>, { onKeyPressed: handleKeys });
