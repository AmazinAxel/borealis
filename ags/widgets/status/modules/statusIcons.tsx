import { Gtk } from 'ags/gtk4';
import { createBinding, createState } from 'ags';
import { streamingMode } from '../../../lib/streamingMode';
import { btPowered } from '../../../lib/bluetooth';
import { volumeIcon } from '../../../lib/audio';
import Battery from 'gi://AstalBattery';
import { getObjects, onPropertiesChanged, stationInterface } from '../../../lib/iwd';

const battery = Battery.get_default();

const batPercentageBind = createBinding(battery, 'percentage');
const batLowBind = batPercentageBind((p) => Math.round(p * 100) < 99);

const [ networkIcon, setNetworkIcon ] = createState('network-wireless-offline-symbolic');
const applyState = (state: unknown) => setNetworkIcon(
  state == 'connected' || state == 'roaming' ? 'network-wireless-symbolic'
    : state == 'connecting' || state == 'disconnecting' ? 'network-wireless-acquiring-symbolic'
      : 'network-wireless-offline-symbolic');

onPropertiesChanged((_path, iface, changed) => iface == stationInterface && 'State' in changed && applyState(changed.State));
getObjects().then((objects) => applyState(Object.values(objects).find((i) => i[stationInterface])?.[stationInterface].State))
  .catch(() => { });

export const Status = () =>
  <box orientation={Gtk.Orientation.VERTICAL} spacing={7} cssClasses={['statusMenu']}>
    <image iconName={volumeIcon} />
    <overlay visible={Boolean(battery.percentage)}>
      <image
        cssClasses={batLowBind((low) => low ? ['batteryIcon', 'dimmed'] : ['batteryIcon'])}
        iconName={createBinding(battery, 'batteryIconName')}
      />
      <label
        $type="overlay"
        cssClasses={createBinding(battery, 'charging')((c) => c ? ['batteryPercent', 'charging'] : ['batteryPercent'])}
        visible={batLowBind}
        label={batPercentageBind((p) => String(Math.round(p * 100)))}
      />
    </overlay>
    <image iconName={networkIcon} />
    <image iconName="bluetooth-active-symbolic" visible={btPowered} />
    <image iconName="notifications-disabled-symbolic" visible={streamingMode} />
  </box>;
