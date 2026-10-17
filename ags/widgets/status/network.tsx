import { createRoot, createState, For, onCleanup } from 'ags';
import { Gtk } from 'ags/gtk4';
import { execAsync } from 'ags/process';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Pango from 'gi://Pango';
import { currentAsideWindow } from '../../lib/asideState';
import { streamingMode } from '../notifications/notifications';

type WifiNet = { ssid: string; security: string; icon: string; connected: boolean; known: boolean; path: string };

// iwd config thingys
const station = 'wlan0';
const iwdBus = 'net.connman.iwd';
const deviceInterface = 'net.connman.iwd.Device';
const stationInterface = 'net.connman.iwd.Station';
const networkInterface = 'net.connman.iwd.Network';

const [ networks, setNetworks ] = createState<WifiNet[]>([]);
const [ scanning, setScanning ] = createState(false);
const [ wifiOn, setWifiOn ] = createState(true);

const openPopovers = new Set<Gtk.Popover>();
const closeAllPopovers = () => { for (const p of openPopovers) p.popdown(); };

const sigIcon = (mbm: number) => {
    const dbm = mbm / 100;
    const n = dbm >= -50 ? 4 : dbm >= -65 ? 3 : dbm >= -75 ? 2 : dbm >= -85 ? 1 : 0; // Signal is in 100*dBm units from iwd
    return `network-wireless-signal-${['none', 'weak', 'ok', 'good', 'excellent'][n]}-symbolic`;
};

const systemBus = Gio.DBus.system;

const iwdCall = (path: string, iface: string, method: string, params: GLib.Variant | null = null) =>
    new Promise<any>((resolve, reject) => systemBus.call(
        iwdBus, path, iface, method, params, null, Gio.DBusCallFlags.NONE, -1, null,
        (bus, res) => {
            try { resolve(bus!.call_finish(res).recursiveUnpack()); }
            catch (e) { reject(e); }
        },
    ));

let stationPath = '';
let devicePath = '';

let listBox: Gtk.Box | null = null;
let powerButton: Gtk.Widget | null = null;
let scanButton: Gtk.Widget | null = null;

const rowBySsid = new Map<string, Gtk.Widget>(); // survives For rebuilds
let focusedSsid: string | null = null; // row to restore after a refresh
const focusTarget = () => {
    if (!wifiOn()) return powerButton;
    const remembered = focusedSsid ? rowBySsid.get(focusedSsid) : undefined;
    if (remembered?.get_mapped()) return remembered;
    const connected = networks.peek().find(n => n.connected);
    const connectedRow = connected && rowBySsid.get(connected.ssid);
    if (connectedRow?.get_mapped()) return connectedRow;
    return listBox?.get_first_child() ?? scanButton;
};

const focusWifiMenu = () => GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
    if (currentAsideWindow.peek() === 'wifi') {
        const target = focusTarget();
        if (target?.get_mapped()) target.grab_focus();
    };
    return GLib.SOURCE_REMOVE;
});

const menuHasFocus = () => {
    const root = listBox?.get_root() as Gtk.Window | null;
    return !!root?.get_focus()?.get_mapped();
};

let subIds: number[] = [];
let coalesceId = 0;

const queueRefresh = () => {
    if (coalesceId) return;
    coalesceId = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
        coalesceId = 0;
        refresh();
        return GLib.SOURCE_REMOVE;
    });
};

const watchIwd = () => { // update dynamically
    if (subIds.length) return;

    subIds.push(systemBus.signal_subscribe(
        iwdBus, 'org.freedesktop.DBus.Properties', 'PropertiesChanged',
        null, null, Gio.DBusSignalFlags.NONE,
        (_bus, _sender, path, _iface, _signal, params) => {
            const [changedIface, changed] = params.recursiveUnpack() as [string, Record<string, any>];
            if (changedIface === stationInterface && path === stationPath && 'Scanning' in changed)
                setScanning(changed.Scanning === true);
            queueRefresh();
        },
    ));

    subIds.push(systemBus.signal_subscribe(
        iwdBus, 'org.freedesktop.DBus.ObjectManager', null,
        null, null, Gio.DBusSignalFlags.NONE,
        queueRefresh,
    ));
};

const unwatchIwd = () => {
    for (const id of subIds) systemBus.signal_unsubscribe(id);
    subIds = [];
    if (coalesceId) {
        GLib.source_remove(coalesceId);
        coalesceId = 0;
    };
};

type ObjMap = Record<string, Record<string, Record<string, any>>>;

let refreshGen = 0;
const refresh = async () => {
    const gen = ++refreshGen;
    try {
        const [objects]: [ObjMap] = await iwdCall('/', 'org.freedesktop.DBus.ObjectManager', 'GetManagedObjects');

        // Locate device and station paths
        for (const [path, ifaces] of Object.entries(objects)) {
            if (ifaces[deviceInterface]?.['Name'] === station) {
                devicePath = path;
                if (stationInterface in ifaces) stationPath = path;
            };
        };
        if (gen !== refreshGen) return;

        const powered: boolean = objects[devicePath]?.[deviceInterface]?.['Powered'] ?? true;
        setWifiOn(powered);
        setScanning(objects[stationPath]?.[stationInterface]?.['Scanning'] === true);

        if (!powered || !stationPath) {
            setNetworks([]);
            return;
        };

        const [ordered]: [[string, number][]] = await iwdCall(stationPath, stationInterface, 'GetOrderedNetworks');
        if (gen !== refreshGen) return;

        const next = ordered
            .map(([netPath, signalMbm]): WifiNet | null => {
                const p = objects[netPath]?.[networkInterface];
                if (!p?.['Name']) return null;
                const kn = p['KnownNetwork'];
                return {
                    ssid: p['Name'] as string,
                    security: p['Type'] as string,
                    icon: sigIcon(signalMbm),
                    connected: p['Connected'] as boolean,
                    known: typeof kn === 'string' && kn !== '' && kn !== '/',
                    path: netPath,
                };
            })
            .filter((n): n is WifiNet => n !== null)
            .sort((a, b) => Number(b.connected) - Number(a.connected));

        if (openPopovers.size || JSON.stringify(next) === JSON.stringify(networks.peek())) return;
        setNetworks(next);

        if (!menuHasFocus()) focusWifiMenu(); // focus in case of a rebuild
    } catch {};
};

const toggleWifi = async () => {
    try {
        if (!devicePath) await refresh();
        const next = !wifiOn();
        await iwdCall(devicePath, 'org.freedesktop.DBus.Properties', 'Set',
            new GLib.Variant('(ssv)', [deviceInterface, 'Powered', new GLib.Variant('b', next)]));
        setWifiOn(next);
        if (!next) setNetworks([]);
        else await refresh();
    } catch {};
};

const scan = async () => {
    if (scanning()) return;
    setScanning(true);
    try {
        if (!stationPath) await refresh();
        await iwdCall(stationPath, stationInterface, 'Scan').catch((e) => {
            if (!String(e).includes('Operation already in progress')) throw e;
        });
        refresh();
    } catch {
        setScanning(false);
    };
};

const NetworkRow = ({ net }: { net: WifiNet }) => {
    let entry: Gtk.Entry | null = null;
    let popover: Gtk.Popover | null = null;
    let disposePopover = () => {};

    const submit = () => {
        const pw = entry?.text ?? '';
        const args = pw
            ? ['iwctl', '--passphrase', pw, 'station', station, 'connect', net.ssid]
            : ['iwctl', 'station', station, 'connect', net.ssid];
        execAsync(args).then(() => { popover?.popdown(); refresh(); }).catch(() => {});
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
                onClosed={() => GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                    if (popover === p) removePopover();
                    queueRefresh();
                    return GLib.SOURCE_REMOVE;
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
        cssClasses={net.connected ? ['active'] : []}
        onClicked={(self) => {
            focusedSsid = net.ssid; // keep focus here through the reorder
            if (net.connected) {
                iwdCall(stationPath, stationInterface, 'Disconnect')
                    .then(refresh).catch(() => {});
            } else if (net.security !== 'open' && !net.known) {
                if (popover) return popover.popdown();
                closeAllPopovers();
                openPasswordPopover(self);
            } else {
                iwdCall(net.path, networkInterface, 'Connect')
                    .then(refresh).catch(() => {});
            }
        }}
        onStateFlagsChanged={(self) => {
            if (self.has_focus) focusedSsid = net.ssid; // remember across refreshes
        }}
        $={(self) => {
            rowBySsid.set(net.ssid, self);
            onCleanup(() => {
                if (rowBySsid.get(net.ssid) === self) rowBySsid.delete(net.ssid);
                removePopover();
            });
        }}
    >
        <box spacing={10}>
            <image iconName={net.icon}/>
            <label hexpand halign={Gtk.Align.START} label={net.ssid} ellipsize={Pango.EllipsizeMode.END}/>
            {net.security !== 'open' && <image iconName="network-wireless-encrypted-symbolic"/>}
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
        <box visible={streamingMode.as(d => !d)} orientation={Gtk.Orientation.VERTICAL}>
            <box>
                <button
                    canTarget={false}
                    hexpand halign={Gtk.Align.START}
                    cssClasses={wifiOn.as(on => [on ? 'active' : 'unpowered'])}
                    onClicked={toggleWifi}
                    onMap={() => { watchIwd(); refresh(); focusWifiMenu(); }}
                    onUnmap={unwatchIwd}
                    $={(self) => powerButton = self}
                >
                    <image iconName={wifiOn.as(on =>
                        on ? 'network-wireless-symbolic' : 'network-wireless-offline-symbolic'
                    )}/>
                </button>
                <button
                    canTarget={false}
                    onClicked={scan}
                    sensitive={scanning.as(s => !s)}
                    visible={wifiOn}
                    cssClasses={scanning.as(s => s ? ['active'] : [])}
                    $={(self) => scanButton = self}
                >
                    <image iconName="view-refresh-symbolic"/>
                </button>
            </box>
            <Gtk.Separator visible={wifiOn}/>
            <scrolledwindow
                hscrollbarPolicy={Gtk.PolicyType.NEVER}
                hexpand vexpand
                propagateNaturalWidth propagateNaturalHeight
                maxContentHeight={500}
                visible={wifiOn}
            >
                <box orientation={Gtk.Orientation.VERTICAL} $={(self) => listBox = self}>
                    <For each={networks}>
                        {(net: WifiNet) => <NetworkRow net={net}/>}
                    </For>
                </box>
            </scrolledwindow>
        </box>
    </box>
