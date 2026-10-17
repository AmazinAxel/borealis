import BluetoothService from 'gi://AstalBluetooth';
import { createBinding, createComputed, createState, For, onCleanup } from 'ags';
import { Gtk } from 'ags/gtk4';
import Wp from 'gi://AstalWp';
import GLib from 'gi://GLib';
import Pango from 'gi://Pango';
import Gdk from 'gi://Gdk';
import { currentAsideWindow } from '../../lib/asideState';
import { timeout } from 'ags/time';

const bluetooth = BluetoothService.get_default();
const audio = Wp.get_default()?.audio; // for auto-sink switching
const bluetoothOn = createBinding(bluetooth, 'isPowered');

const hook = <T extends { connect(s: string, cb: () => void): number; disconnect(id: number): void }>(
    obj: T | null | undefined, signal: string, cb: () => void,
) => {
    const id = obj?.connect(signal, cb);
    if (id) onCleanup(() => obj!.disconnect(id));
};

let pendingSinkId = 0;
const switchToBluetoothSink = (address: string) => {
    if (!audio) return;
    const wanted = address.replaceAll(':', '_');
    const take = () => {
        const sink = (audio.speakers ?? []).find(s =>
            (s.get_pw_property('node.name') ?? '').includes(wanted));
        if (!sink) return false;
        sink.isDefault = true;
        return true;
    };
    const stop = () => { if (pendingSinkId) { audio.disconnect(pendingSinkId); pendingSinkId = 0; } };

    stop();
    if (take()) return;
    const id = pendingSinkId = audio.connect('notify::speakers', () => take() && stop());
    timeout(10000, () => pendingSinkId === id && stop());
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
    try {
        const [ ok, contents ] = GLib.file_get_contents(orderPath);
        return ok ? JSON.parse(new TextDecoder().decode(contents)) : [];
    } catch { return []; }
};
const [ order, setOrder ] = createState<string[]>(loadOrder());
const saveOrder = (addresses: string[]) => {
    const next = [ ...addresses, ...order.peek().filter(a => !addresses.includes(a)) ];
    setOrder(next);
    GLib.mkdir_with_parents(GLib.path_get_dirname(orderPath), 0o755);
    GLib.file_set_contents(orderPath, JSON.stringify(next));
};

const isKnown = (d: BluetoothService.Device) => d.paired || d.trusted;
const visibleDevices = createComputed((track) => {
    if (!track(menuOpen)) return [];
    const ord = track(order);
    const rank = (d: BluetoothService.Device) =>
        isKnown(d) ? ord.indexOf(d.address) + 1 || ord.length + 1 : Infinity;
    return [ ...track(devicesBind) ].sort((a, b) => (rank(a) - rank(b)) || 0);
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
    return devices.find(d => d.connected && listed(d)) ?? devices.find(listed) ?? null;
};

const knownDevices = () => visibleDevices.peek().filter(d => isKnown(d) && listed(d));
const moveDevice = (device: BluetoothService.Device, delta: number) => {
    const list = knownDevices();
    const i = list.indexOf(device), j = i + delta;
    if (i < 0 || j < 0 || j >= list.length) return false;
    [ list[i], list[j] ] = [ list[j], list[i] ];
    saveOrder(list.map(d => d.address));
    return true;
};

let focusedDevice: BluetoothService.Device | null = null;
const focusDevice = () => (focusedDevice && listed(focusedDevice) ? focusedDevice : firstListed());

const focusOnOpen = (self: Gtk.Widget, when: () => boolean) =>
    onCleanup(currentAsideWindow.subscribe(() => {
        if (currentAsideWindow.peek() !== 'bluetooth') return;
        GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            if (currentAsideWindow.peek() === 'bluetooth' && when()) self.grab_focus();
            return GLib.SOURCE_REMOVE;
        });
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

    const visible = createComputed((track) =>
        hasName(track(alias), device.address)
            && (track(paired) || track(trusted) || track(connected)
                || track(discovering) || track(stickyKeys).has(device.address)));

    let pairId = 0;
    const stopPairWatch = () => {
        if (pairId) device.disconnect(pairId);
        pairId = 0;
    };
    onCleanup(stopPairWatch);

    const connectAndSwitch = () => device.connect_device((_, res) => {
        try {
            device.connect_device_finish(res);
            switchToBluetoothSink(device.address);
        } catch {};
    });

    const refocusLater = (self: Gtk.Widget) => GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
        if (currentAsideWindow.peek() === 'bluetooth'
            && focusDevice() === device && self.get_mapped())
            self.grab_focus();
        return GLib.SOURCE_REMOVE;
    });

    return <button hexpand
        canTarget={false}
        visible={visible}
        sensitive={connecting(c => !c)}
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
                return device.disconnect_device((_, res) => { try { device.disconnect_device_finish(res); } catch {}; });

            stickyAdd(device.address);
            if (bluetooth.adapter?.discovering) bluetooth.adapter.stop_discovery();
            if (device.paired) {
                device.trusted = true;
                return connectAndSwitch();
            }

            stopPairWatch();
            const id = pairId = device.connect('notify::paired', () => {
                if (!device.paired) return;
                stopPairWatch();
                device.trusted = true;
                saveOrder(knownDevices().map(d => d.address));
                connectAndSwitch();
            });
            timeout(30000, () => pairId === id && stopPairWatch());
            device.pair();
        }}
    >
        <Gtk.EventControllerKey onKeyPressed={(ctrl, key, _, state) => {
            if (key == Gdk.KEY_BackSpace && isKnown(device) && !bluetooth.adapter?.discovering)
                bluetooth.adapter?.remove_device(device);
            const delta = { [Gdk.KEY_Up]: -1, [Gdk.KEY_k]: -1, [Gdk.KEY_Down]: 1, [Gdk.KEY_j]: 1 }[Gdk.keyval_to_lower(key)];
            if (!delta || !(state & Gdk.ModifierType.SHIFT_MASK)) return false;
            if (moveDevice(device, delta)) GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                ctrl.get_widget()?.grab_focus();
                return GLib.SOURCE_REMOVE;
            });
            return true;
        }}/>
        <box hexpand valign={Gtk.Align.CENTER} spacing={10}>
            <image iconName={device.icon + '-symbolic'}/>
            <label label={alias(nameSubstitute)} halign={Gtk.Align.START} hexpand ellipsize={Pango.EllipsizeMode.END}/>
            <label
                visible={createComputed((track) => track(connected) && track(battery) >= 0)}
                label={battery((p) => Math.round(p * 100) + '%')}
                halign={Gtk.Align.END}
            />
        </box>
    </button>;
};

export default () => {
    let listBox: Gtk.Box | null = null;

    return <box orientation={Gtk.Orientation.VERTICAL} $={wireMenuLifecycle}>
        <box>
            <button
                canTarget={false}
                hexpand halign={Gtk.Align.START}
                onClicked={() => bluetooth.toggle()}
                cssClasses={bluetoothOn.as(power => [power ? 'active' : 'unpowered'])}
                $={(self) => focusOnOpen(self, () => !bluetooth.isPowered)}
            >
                <image iconName="bluetooth-active-symbolic"/>
            </button>
            <button
                canTarget={false}
                onClicked={() => {
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
                visible={bluetoothOn}
                cssClasses={discovering.as((d) => d ? ['active'] : [])}
                $={(self) => focusOnOpen(self, () => bluetooth.isPowered && !focusDevice())}
            >
                <image iconName="view-refresh-symbolic"/>
            </button>
        </box>
        <Gtk.Separator visible={bluetoothOn}/>
        <scrolledwindow
            hscrollbarPolicy={Gtk.PolicyType.NEVER}
            hexpand vexpand
            propagateNaturalWidth propagateNaturalHeight
            maxContentHeight={500}
            visible={bluetoothOn}
            $={() => hook(bluetooth, 'notify::is-powered', () => {
                if (bluetooth.isPowered && !focusDevice()) listBox?.get_first_child()?.grab_focus();
            })}
        >
            <box orientation={Gtk.Orientation.VERTICAL} $={(self) => listBox = self}>
                <For each={visibleDevices}>
                    {(device: BluetoothService.Device) => <DeviceRow device={device}/>}
                </For>
            </box>
        </scrolledwindow>
    </box>;
};
