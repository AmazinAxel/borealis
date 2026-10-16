import { Gtk } from 'ags/gtk4'
import { createBinding, createState } from "ags"
import { streamingMode } from '../../notifications/notifications';
import { btPowered } from '../../../lib/bluetooth';
import Wp from 'gi://AstalWp';
import Battery from 'gi://AstalBattery';
import Gio from 'gi://Gio';

const audio = Wp.get_default()!.audio;
const battery = Battery.get_default();

const batPercentageBind = createBinding(battery, 'percentage');
const batLowBind = batPercentageBind((p) => Math.round(p * 100) < 99);

const iwdBus = 'net.connman.iwd';
const stationInterface = 'net.connman.iwd.Station';
const systemBus = Gio.DBus.system;

const [ networkIcon, setNetworkIcon ] = createState('network-wireless-offline-symbolic');

const iconForState = (state?: string) =>
    (state === 'connected' || state === 'roaming') ? 'network-wireless-symbolic'
        : (state === 'connecting' || state === 'disconnecting') ? 'network-wireless-acquiring-symbolic'
        : 'network-wireless-offline-symbolic';

const applyState = (state?: string) => {
  if (!state) return;
  const icon = iconForState(state);
  if (icon !== networkIcon.peek()) setNetworkIcon(icon);
};

systemBus.signal_subscribe(
  iwdBus, 'org.freedesktop.DBus.Properties', 'PropertiesChanged',
  null, stationInterface, Gio.DBusSignalFlags.NONE,
  (_c, _s, _p, _i, _sig, params) => {
    const [, changed] = params.recursiveUnpack() as [string, Record<string, any>];
    if ('State' in changed) applyState(changed.State);
  },
);

systemBus.call(
  iwdBus, '/', 'org.freedesktop.DBus.ObjectManager', 'GetManagedObjects',
  null, null, Gio.DBusCallFlags.NONE, -1, null,
  (conn, res) => {
    try {
      const [objects] = conn!.call_finish(res).recursiveUnpack() as [Record<string, Record<string, any>>];
      for (const ifaces of Object.values(objects)) {
        const station = ifaces[stationInterface];
        if (station && 'State' in station) { applyState(station.State); break; }
      };
    } catch {  };
  },
);

export const Status = () =>
  <box orientation={Gtk.Orientation.VERTICAL} spacing={7} cssClasses={['statusMenu']}>
    <image iconName={createBinding(audio, 'defaultSpeaker', 'volumeIcon')}/>
    <overlay visible={Boolean(battery.percentage)}>
      <image
        cssClasses={batLowBind((low) => low ? ['batteryIcon', 'dimmed'] : ['batteryIcon'])}
        iconName={createBinding(battery, 'batteryIconName')}
      />
      <label
        $type='overlay'
        cssClasses={createBinding(battery, 'charging')((c) => c ? ['batteryPercent', 'charging'] : ['batteryPercent'])}
        visible={batLowBind}
        label={batPercentageBind((p) => String(Math.round(p * 100)))}
      />
    </overlay>
    <image iconName={networkIcon}/>
    <image iconName='bluetooth-active-symbolic' visible={btPowered}/>
    <image iconName='notifications-disabled-symbolic' visible={streamingMode}/>
  </box>
