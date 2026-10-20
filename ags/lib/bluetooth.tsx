import AstalBluetooth from 'gi://AstalBluetooth';
import Gio from 'gi://Gio';
import { createState, With } from 'ags';

export const [ btPowered, setBtPowered ] = createState(false);
const [ menu, setMenu ] = createState<{ Menu: () => JSX.Element } | null>(null);

let started = false;
Gio.bus_watch_name(Gio.BusType.SYSTEM, 'org.bluez', Gio.BusNameWatcherFlags.NONE, () => {
  if (started) return;
  started = true;
  const bt = AstalBluetooth.get_default();
  setBtPowered(bt.isPowered);
  bt.connect('notify::is-powered', () => setBtPowered(bt.isPowered));
  import('../widgets/status/bluetooth').then((m) => setMenu({ Menu: m.default }));
}, null);

export default () =>
  <With value={menu}>
    {(m) => m ? <m.Menu /> : <box />}
  </With>;
