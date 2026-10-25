import { createComputed, createRoot, createState, For, onCleanup } from 'ags';
import { Gtk } from 'ags/gtk4';
import { execAsync } from 'ags/process';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Pango from 'gi://Pango';
import { currentAsideWindow, focusAside } from '../../lib/asideState';
import { streamingMode } from '../../lib/streamingMode';
import { bus, iwdBus, iwdCall, getObjects, onPropertiesChanged, deviceInterface, stationInterface, networkInterface } from '../../lib/iwd';
import idle, { idleOnce } from '../../lib/idle';
import DeviceMenu from '../../lib/deviceMenu';

type WifiNet = { ssid: string, security: string, level: number, known: boolean };

const station = 'wlan0';
const levels = ['none', 'weak', 'ok', 'good', 'excellent'];

const [ paths, setPaths ] = createState<string[]>([]);
const [ nets, setNets ] = createState<Record<string, WifiNet>>({});
const [ connected, setConnected ] = createState('');
const [ connecting, setConnecting ] = createState('');
const [ scanning, setScanning ] = createState(false);
const [ wifiOn, setWifiOn ] = createState(true);

const openPopovers = new Set<Gtk.Popover>();
const closeAllPopovers = () => { for (const p of openPopovers) p.popdown(); };

const sigLevel = (mbm: number) => { // Signal is in 100*dBm units from iwd
  const dbm = mbm / 100;
  return dbm >= -50 ? 4 : dbm >= -65 ? 3 : dbm >= -75 ? 2 : dbm >= -85 ? 1 : 0;
};

let stationPath = '';
let devicePath = '';
let pending = '';

let listBox: Gtk.Box | null = null;
let powerButton: Gtk.Widget | null = null;
let scanButton: Gtk.Widget | null = null;

const rowByPath = new Map<string, Gtk.Widget>();
let focusedPath: string | null = null; // row to restore after a refresh
const focusTarget = () => {
  if (!wifiOn.peek()) return powerButton;
  for (const path of [focusedPath, connected.peek()]) {
    const row = path && rowByPath.get(path);
    if (row && row.get_mapped()) return row;
  }
  return listBox?.get_first_child() ?? scanButton;
};

const focusWifiMenu = () => focusAside('wifi', focusTarget);

let subIds: number[] = [];
const queueRefresh = idleOnce(() => refresh());

const watchIwd = () => { // update dynamically
  if (subIds.length) return;
  refresh();

  subIds.push(onPropertiesChanged((path, iface, changed) => {
    if (iface === stationInterface && path === stationPath && changed.Scanning === false) setScanning(false);
    queueRefresh();
  }));

  subIds.push(bus.signal_subscribe(
    iwdBus, 'org.freedesktop.DBus.ObjectManager', null,
    null, null, Gio.DBusSignalFlags.NONE,
    queueRefresh,
  ));
};

const unwatchIwd = () => {
  for (const id of subIds) bus.signal_unsubscribe(id);
  subIds = [];
  setScanning(false);
};

const clear = () => {
  setPaths([]);
  setNets({});
  setConnected('');
  setConnecting('');
};

let refreshGen = 0;
const refresh = async () => {
  const gen = ++refreshGen;
  try {
    const objects = await getObjects();

    // Locate device and station paths
    for (const [ path, ifaces ] of Object.entries(objects)) {
      if (ifaces[deviceInterface]?.['Name'] === station) {
        devicePath = path;
        if (stationInterface in ifaces) stationPath = path;
      }
    }
    if (gen !== refreshGen) return;

    const powered = objects[devicePath]?.[deviceInterface]?.['Powered'] !== false;
    setWifiOn(powered);
    if (!powered || !stationPath) return clear();

    const [ ordered ] = await iwdCall<[[string, number][]]>(stationPath, stationInterface, 'GetOrderedNetworks');
    if (gen !== refreshGen || openPopovers.size) return;

    const st = objects[stationPath]?.[stationInterface] ?? {};
    const current = typeof st['ConnectedNetwork'] === 'string' ? st['ConnectedNetwork'] : '';
    const joining = st['State'] === 'connecting';
    setConnected(joining ? '' : current);
    setConnecting(joining ? current : pending);

    const next: Record<string, WifiNet> = {};
    for (const [ path, mbm ] of ordered) {
      const p = objects[path]?.[networkInterface];
      if (!p?.['Name']) continue;
      const kn = p['KnownNetwork'];
      next[path] = {
        ssid: p['Name'] as string,
        security: p['Type'] as string,
        level: sigLevel(mbm),
        known: typeof kn === 'string' && kn !== '' && kn !== '/',
      };
    }

    const order = Object.keys(next).sort((a, b) =>
      Number(b === current) - Number(a === current)
      || next[b].level - next[a].level
      || next[a].ssid.localeCompare(next[b].ssid));

    if (JSON.stringify(next) !== JSON.stringify(nets.peek())) setNets(next);
    if (order.join() !== paths.peek().join()) {
      setPaths(order);
      if (!listBox?.get_root()?.get_focus()?.is_ancestor(listBox)) focusWifiMenu();
    }
  } catch { }
};

const toggleWifi = async () => {
  try {
    if (!devicePath) await refresh();
    const next = !wifiOn.peek();
    await iwdCall(devicePath, 'org.freedesktop.DBus.Properties', 'Set',
      new GLib.Variant('(ssv)', [deviceInterface, 'Powered', new GLib.Variant('b', next)]));
    setWifiOn(next);
    if (!next) clear();
    else await refresh();
  } catch { }
};

const scan = async () => {
  if (scanning.peek()) return;
  setScanning(true);
  try {
    if (!stationPath) await refresh();
    await iwdCall(stationPath, stationInterface, 'Scan').catch((e) => {
      if (!String(e).includes('Operation already in progress')) throw e;
    });
  } catch {
    setScanning(false);
  }
};

const join = (path: string, attempt: Promise<unknown>) => {
  pending = path;
  setConnecting(path);
  attempt.catch(() => { }).finally(() => {
    if (pending === path) pending = '';
    refresh();
  });
};

currentAsideWindow.subscribe(() => currentAsideWindow.peek() === 'wifi' ? watchIwd() : unwatchIwd());

const NetworkRow = ({ path }: { path: string }) => {
  const net = nets((m) => m[path] ?? { ssid: '', security: 'open', level: 0, known: false });
  let entry: Gtk.Entry | null = null;
  let popover: Gtk.Popover | null = null;
  let disposePopover = () => { };

  const submit = () => {
    const { ssid } = net.peek();
    const pw = entry?.text ?? '';
    popover?.popdown();
    join(path, execAsync(pw
      ? ['iwctl', '--passphrase', pw, 'station', station, 'connect', ssid]
      : ['iwctl', 'station', station, 'connect', ssid]));
  };

  const removePopover = () => {
    if (!popover) return;
    openPopovers.delete(popover);
    popover.unparent();
    popover = entry = null;
    disposePopover();
  };

  const openPasswordPopover = (self: Gtk.Widget) => {
    const p: Gtk.Popover = popover = createRoot((dispose) => {
      disposePopover = dispose;
      return <popover
        onClosed={() => idle(() => {
          if (popover === p) removePopover();
          queueRefresh();
        })}
      >
        <entry
          hexpand
          visibility={false}
          placeholderText="Password"
          onActivate={submit}
          $={(self) => entry = self}
        />
      </popover> as Gtk.Popover;
    });
    p.set_parent(self);
    openPopovers.add(p);
    p.popup();
    entry?.grab_focus();
  };

  return <button
    canTarget={false}
    cssClasses={createComputed((track) =>
      track(connecting) === path ? ['connecting']
        : track(connected) === path ? ['active']
          : [])}
    onClicked={(self) => {
      if (connecting.peek() === path) return;
      const { security, known } = net.peek();
      if (connected.peek() === path) {
        iwdCall(stationPath, stationInterface, 'Disconnect')
          .then(refresh).catch(() => { });
      } else if (security !== 'open' && !known) {
        if (popover) return popover.popdown();
        closeAllPopovers();
        openPasswordPopover(self);
      } else {
        join(path, iwdCall(path, networkInterface, 'Connect'));
      }
    }}
    onStateFlagsChanged={(self) => {
      if (self.has_focus) focusedPath = path; // remember across refreshes
    }}
    $={(self) => {
      rowByPath.set(path, self);
      onCleanup(() => {
        if (rowByPath.get(path) === self) rowByPath.delete(path);
        removePopover();
      });
    }}
  >
    <box spacing={10}>
      <image iconName={net((n) => `network-wireless-signal-${levels[n.level]}-symbolic`)} />
      <label hexpand xalign={0} label={net((n) => n.ssid)} ellipsize={Pango.EllipsizeMode.END} maxWidthChars={1} />
      <image visible={net((n) => n.security !== 'open')} iconName="network-wireless-encrypted-symbolic" />
    </box>
  </button>;
};

export default () =>
  <box orientation={Gtk.Orientation.VERTICAL}>
    <label
      visible={streamingMode}
      label="Streaming mode enabled"
      halign={Gtk.Align.CENTER}
    />
    <box visible={streamingMode((d) => !d)}>
      <DeviceMenu
        upTo="scan"
        powered={wifiOn}
        powerIcon={wifiOn((on) => on ? 'network-wireless-symbolic' : 'network-wireless-offline-symbolic')}
        scanning={scanning}
        scanSensitive={scanning((s) => !s)}
        empty={paths((p) => !p.length)}
        onPower={toggleWifi}
        onScan={scan}
        power={(self) => {
          powerButton = self;
          self.connect('map', focusWifiMenu);
        }}
        scan={(self) => scanButton = self}
        list={(self) => listBox = self}
      >
        <For each={paths}>
          {(path: string) => <NetworkRow path={path} />}
        </For>
      </DeviceMenu>
    </box>
  </box>;
