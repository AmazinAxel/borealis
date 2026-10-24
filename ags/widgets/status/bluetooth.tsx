import BluetoothService from 'gi://AstalBluetooth';
import { createBinding, createComputed, createState, For, onCleanup, type Accessor } from 'ags';
import { Gtk } from 'ags/gtk4';
import { audio } from '../../lib/audio';
import { readFile, writeFile } from 'ags/file';
import idle from '../../lib/idle';
import DeviceMenu from '../../lib/deviceMenu';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Pango from 'gi://Pango';
import Gdk from 'gi://Gdk';
import { currentAsideWindow } from '../../lib/asideState';
import { btPowered } from '../../lib/bluetooth';
import { timeout } from 'ags/time';

const bluetooth = BluetoothService.get_default();

const bluez = (path: string, iface: string, method: string, args: GLib.Variant | null = null, onDone?: () => void) =>
  Gio.DBus.system.call('org.bluez', path, iface, method, args, null, Gio.DBusCallFlags.NONE, 60000, null, (conn, res) => {
    try {
      conn!.call_finish(res);
      onDone?.();
    } catch { }
  });
const devicePath = (d: BluetoothService.Device) => `${d.adapter}/dev_${d.address.replace(/:/g, '_')}`;
const trust = (d: BluetoothService.Device) => bluez(devicePath(d), 'org.freedesktop.DBus.Properties', 'Set',
  new GLib.Variant('(ssv)', ['org.bluez.Device1', 'Trusted', new GLib.Variant('b', true)]));

const [ batteryPaths, setBatteryPaths ] = createState<ReadonlySet<string>>(new Set());
const setHasBattery = (path: string, has: boolean) => {
  const cur = batteryPaths.peek();
  if (cur.has(path) === has) return;
  const next = new Set(cur);
  if (has) next.add(path);
  else next.delete(path);
  setBatteryPaths(next);
};
Gio.DBus.system.signal_subscribe('org.bluez', 'org.freedesktop.DBus.ObjectManager', null, '/', null, Gio.DBusSignalFlags.NONE,
  (_conn, _sender, _path, _iface, signal, params) => {
    const [ path, ifaces ] = params.deepUnpack() as [string, Record<string, unknown> | string[]];
    if (signal === 'InterfacesAdded' && 'org.bluez.Battery1' in ifaces) setHasBattery(path, true);
    if (signal === 'InterfacesRemoved' && (ifaces as string[]).includes('org.bluez.Battery1')) setHasBattery(path, false);
  });
Gio.DBus.system.call('org.bluez', '/', 'org.freedesktop.DBus.ObjectManager', 'GetManagedObjects', null, null,
  Gio.DBusCallFlags.NONE, -1, null, (conn, res) => {
    try {
      const [ objects ] = conn!.call_finish(res).deepUnpack() as [Record<string, Record<string, unknown>>];
      for (const [ path, ifaces ] of Object.entries(objects))
        if ('org.bluez.Battery1' in ifaces) setHasBattery(path, true);
    } catch { }
  });

const hook = <T extends { connect(s: string, cb: () => void): number; disconnect(id: number): void }>(
  obj: T | null | undefined, signal: string, cb: () => void,
) => {
  const id = obj?.connect(signal, cb);
  if (id) onCleanup(() => obj!.disconnect(id));
};

let stopPending = () => { };
const switchToBluetoothSink = (device: BluetoothService.Device) => {
  const wanted = device.address.replaceAll(':', '_');
  const take = () => {
    const sink = (audio.speakers ?? []).find((s) =>
      (s.get_pw_property('node.name') ?? '').includes(wanted));
    if (!sink) return false;
    sink.isDefault = true;
    return true;
  };

  stopPending();
  if (take()) return;
  const sinkId = audio.connect('notify::speakers', () => take() && stopPending());
  const deviceId = device.connect('notify::connected', () => !device.connected && stopPending());
  stopPending = () => {
    audio.disconnect(sinkId);
    device.disconnect(deviceId);
    stopPending = () => { };
  };
};

const [ discovering, setDiscovering ] = createState(false);
let adapterId = 0;
let wiredAdapter: BluetoothService.Adapter | null = null;
const wireAdapter = (adapter: BluetoothService.Adapter | null) => {
  if (wiredAdapter && adapterId) wiredAdapter.disconnect(adapterId);
  wiredAdapter = adapter;
  adapterId = 0;
  if (!adapter) return setDiscovering(false);
  setDiscovering(adapter.discovering);
  adapterId = adapter.connect('notify::discovering', () => setDiscovering(adapter.discovering));
};
wireAdapter(bluetooth.adapter);
bluetooth.connect('notify::adapter', () => wireAdapter(bluetooth.adapter));

const [ stickyKeys, setStickyKeys ] = createState<ReadonlySet<string>>(new Set());
const stickyAdd = (address: string) => {
  if (stickyKeys.peek().has(address)) return;
  const next = new Set(stickyKeys.peek());
  next.add(address);
  setStickyKeys(next);
};
const stickyClear = () => stickyKeys.peek().size && setStickyKeys(new Set());

let scanToken = 0;

const devicesBind = createBinding(bluetooth, 'devices');
const menuOpen = currentAsideWindow((a) => a === 'bluetooth');

const orderPath = GLib.get_user_state_dir() + '/ags/bluetooth-order.json';
const loadOrder = (): string[] => {
  try { return JSON.parse(readFile(orderPath)); } catch { return []; }
};
const [ order, setOrder ] = createState<string[]>(loadOrder());
const saveOrder = (addresses: string[]) => {
  const next = [...addresses, ...order.peek().filter((a) => !addresses.includes(a))];
  setOrder(next);
  writeFile(orderPath, JSON.stringify(next));
};

const isKnown = (d: BluetoothService.Device) => d.paired || d.trusted;
const visibleDevices = createComputed((track) => {
  if (!track(menuOpen)) return [];
  const ord = track(order);
  const rank = (d: BluetoothService.Device) =>
    isKnown(d) ? ord.indexOf(d.address) + 1 || ord.length + 1 : Infinity;
  return [...track(devicesBind)].sort((a, b) => (rank(a) - rank(b)) || 0);
});

const hasName = (alias: string, address: string) =>
  !!alias && alias.replaceAll('-', ':') != address;
const NAMES: Record<string, string> = {
  S80A: 'Touchscreen Earbuds',
  MINI_KEYBOARD: '2-key Presenter',
  K38: 'Karaoke Speaker',
  'MOU-302': 'Ergo Mouse',
};
const nameSubstitute = (name: string) => NAMES[name] ?? name ?? '';

const listed = (d: BluetoothService.Device) =>
  hasName(d.alias, d.address)
  && (d.paired || d.trusted || d.connected || discovering.peek() || stickyKeys.peek().has(d.address));

const firstListed = () => {
  const devices = devicesBind.peek();
  return devices.find((d) => d.connected && listed(d)) ?? devices.find(listed) ?? null;
};

const knownDevices = () => visibleDevices.peek().filter((d) => isKnown(d) && listed(d));
const moveDevice = (device: BluetoothService.Device, delta: number) => {
  const list = knownDevices();
  const i = list.indexOf(device), j = i + delta;
  if (i < 0 || j < 0 || j >= list.length) return false;
  [ list[i], list[j] ] = [ list[j], list[i] ];
  saveOrder(list.map((d) => d.address));
  return true;
};

let focusedDevice: BluetoothService.Device | null = null;
const focusDevice = () => (focusedDevice && listed(focusedDevice) ? focusedDevice : firstListed());

const focusOnOpen = (self: Gtk.Widget, when: () => boolean) =>
  onCleanup(currentAsideWindow.subscribe(() => {
    if (currentAsideWindow.peek() !== 'bluetooth') return;
    idle(() => currentAsideWindow.peek() === 'bluetooth' && when() && self.grab_focus());
  }));

const wireMenuLifecycle = () =>
  onCleanup(currentAsideWindow.subscribe(() => {
    if (currentAsideWindow.peek() === 'bluetooth') return;
    if (bluetooth.adapter?.discovering) bluetooth.adapter.stop_discovery();
    stickyClear();
  }));

const DeviceRow = ({ device }: { device: BluetoothService.Device }) => {
  const connected = createBinding(device, 'connected');
  const connecting = createBinding(device, 'connecting');
  const battery = createBinding(device, 'batteryPercentage');
  const paired = createBinding(device, 'paired');
  const trusted = createBinding(device, 'trusted');
  const alias = createBinding(device, 'alias');

  const visible = createComputed((track) => {
    ([alias, paired, trusted, connected, discovering, stickyKeys] as Accessor<unknown>[]).forEach((a) => track(a));
    return listed(device);
  });

  const connectAndSwitch = () => device.connect_device((_, res) => {
    try {
      device.connect_device_finish(res);
      switchToBluetoothSink(device);
    } catch { }
  });

  const refocusLater = (self: Gtk.Widget) => idle(() => {
    if (currentAsideWindow.peek() === 'bluetooth'
      && focusDevice() === device && self.get_mapped())
      self.grab_focus();
  });

  return <button hexpand
    canTarget={false}
    visible={visible}
    sensitive={connecting((c) => !c)}
    cssClasses={createComputed((track) =>
      track(connecting) ? ['connecting']
        : track(connected) ? ['active']
          : []
    )}
    onStateFlagsChanged={(self) => {
      if (self.has_focus) focusedDevice = device; // remember
    }}
    onMap={refocusLater}
    $={(self) => {
      hook(device, 'notify::connected', () => refocusLater(self));
      hook(device, 'notify::connecting', () => refocusLater(self));

      onCleanup(() => {
        if (focusedDevice === device) focusedDevice = null; // row gone
      });
    }}
    onClicked={() => {
      focusedDevice = device; // keep focus here
      if (device.connected)
        return device.disconnect_device((_, res) => { try { device.disconnect_device_finish(res); } catch { } });

      stickyAdd(device.address);
      if (bluetooth.adapter?.discovering) bluez(device.adapter, 'org.bluez.Adapter1', 'StopDiscovery');
      if (device.paired) {
        trust(device);
        return connectAndSwitch();
      }

      bluez(devicePath(device), 'org.bluez.Device1', 'Pair', null, () => {
        trust(device);
        saveOrder(knownDevices().map((d) => d.address));
        connectAndSwitch();
      });
    }}
  >
    <Gtk.EventControllerKey onKeyPressed={(ctrl, key, _, state) => {
      if (key == Gdk.KEY_BackSpace && isKnown(device) && !bluetooth.adapter?.discovering)
        bluetooth.adapter?.remove_device(device);
      const delta = { [Gdk.KEY_Up]: -1, [Gdk.KEY_k]: -1, [Gdk.KEY_Down]: 1, [Gdk.KEY_j]: 1 }[Gdk.keyval_to_lower(key)];
      if (!delta || !(state & Gdk.ModifierType.SHIFT_MASK)) return false;
      if (moveDevice(device, delta)) idle(() => ctrl.get_widget()?.grab_focus());
      return true;
    }} />
    <box hexpand valign={Gtk.Align.CENTER} spacing={10}>
      <image iconName={device.icon + '-symbolic'} />
      <label label={alias(nameSubstitute)} halign={Gtk.Align.START} hexpand ellipsize={Pango.EllipsizeMode.END} />
      <label
        visible={createComputed((track) => track(connected) && track(battery) >= 0
          && track(batteryPaths).has(devicePath(device)))}
        label={battery((p) => Math.round(p * 100) + '%')}
        halign={Gtk.Align.END}
      />
    </box>
  </button>;
};

export default () => {
  let listBox: Gtk.Box | null = null;
  wireMenuLifecycle();
  hook(bluetooth, 'notify::is-powered', () => {
    if (bluetooth.isPowered && !focusDevice()) listBox?.get_first_child()?.grab_focus();
  });

  return <DeviceMenu
    powered={btPowered}
    powerIcon="bluetooth-active-symbolic"
    scanning={discovering}
    onPower={() => bluetooth.toggle()}
    onScan={() => {
      const adapter = bluetooth.adapter;
      if (!adapter) return;
      if (adapter.discovering) return adapter.stop_discovery();
      adapter.start_discovery();
      const token = ++scanToken;
      timeout(60000, () => {
        if (token === scanToken && bluetooth.adapter?.discovering)
          bluetooth.adapter.stop_discovery();
      });
    }}
    power={(self) => focusOnOpen(self, () => !bluetooth.isPowered)}
    scan={(self) => focusOnOpen(self, () => bluetooth.isPowered && !focusDevice())}
    list={(self) => listBox = self}
  >
    <For each={visibleDevices}>
      {(device: BluetoothService.Device) => <DeviceRow device={device} />}
    </For>
  </DeviceMenu>;
};
