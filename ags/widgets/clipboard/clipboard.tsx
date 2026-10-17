import { execAsync, createSubprocess } from 'ags/process';
import { timeout } from 'ags/time';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Gdk from 'gi://Gdk';
import { ClipboardItem, entryPath, cacheDir, videoExts, binaryData } from './clipboardItem';
import { openCompress } from './compress';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';
import { streamingMode } from '../notifications/notifications';

const hide = () => app.get_window('clipboard')?.hide();
const items = new Map<string, { mime: string, path: string | null, child: Gtk.Widget }>();

const list = new Gtk.ListBox({ canTarget: false });
list.set_sort_func((a, b) => Number(b.child!.name) - Number(a.child!.name));
list.connect('row-activated', (_, row) => {
    hide();

    const id = row.child!.name;
    const type = items.get(id)?.mime ?? 'text/plain';
    execAsync(['bash', '-c', `cliphist decode ${id} | wl-copy -t ${type} 2>/dev/null`]);
});

streamingMode.subscribe(() => {
    list.remove_all(); // rebuild
    items.clear();
    refreshItems();
});

let inFlight: Promise<void> = Promise.resolve();
const refreshItems = () => inFlight = inFlight.then(async () => {
    const entries = (await execAsync('cliphist list')).split('\n')
        .map((entry) => entry.split('\t') as [string, string])
        .filter(([id, content]) => id && content);

    entries.forEach(([id, content]) => {
        if (items.has(id)) return;

        const image = content.match(binaryData);
        const path = entryPath(id, content);
        const child = ClipboardItem(id, content, path, image) as Gtk.Widget;
        list.append(child);

        items.set(id, { path, child, mime:
            image ? `image/${image[1]}`
            : content.trim().startsWith('file://') ? 'text/uri-list' // paste the ACTUAL file
            : 'text/plain' });
    });

    const current = new Set(entries.map(([id]) => id));
    const stale = [...items].filter(([id]) => !current.has(id));

    stale.forEach(([id, { child }]) => {
        list.remove(child.get_parent() as Gtk.Widget); // ListBoxRow parent
        items.delete(id);
    });

    // Their decodes and thumbnails are dead weight now
    if (stale.length) execAsync(['bash', '-c',
        'rm -f ' + stale.map(([id]) => `${cacheDir}/${id}.*`).join(' ')]);
}).catch(() => {});
refreshItems();

// build on copy
createSubprocess('', ['wl-paste', '--watch', 'echo', 'copied'])
    .subscribe(() => timeout(200, refreshItems));

const focusTop = () => {
    const first = list.get_row_at_index(0);

    list.select_row(first);
    first?.grab_focus();
};

const selectedRow = () => list.get_selected_row() ?? list.get_row_at_index(0);
const selectedId = () => selectedRow()?.child?.name ?? '';

const showInFileManager = (file: string) => Gio.DBus.session.call(
    'org.freedesktop.FileManager1',
    '/org/freedesktop/FileManager1',
    'org.freedesktop.FileManager1',
    'ShowItems',
    new GLib.Variant('(ass)', [[GLib.filename_to_uri(file, null)], '']),
    null, Gio.DBusCallFlags.NONE, -1, null, null);

// want: null any file, videoExts videos only, notVideo everything else
const notVideo = { test: (f: string) => !videoExts.test(f) };

// streaming mode skips thumbnails, so image entries have no decode on disk yet
const withFile = (want: { test: (f: string) => boolean } | null,
                  action: (file: string, id: string) => void) => {
    const id = selectedId();
    const { path, mime } = items.get(id) ?? {};
    if (!path || (want && !want.test(path))) return;

    const run = () => GLib.file_test(path, GLib.FileTest.EXISTS) && (hide(), action(path, id));

    if (GLib.file_test(path, GLib.FileTest.EXISTS) || !mime?.startsWith('image/')) return run();

    execAsync(['bash', '-c', `cliphist decode ${id} > ${path}`]).then(run).catch(() => {});
};

const actions: Record<number, () => void> = {
    [Gdk.KEY_Return]: () => selectedRow()?.activate(),
    [Gdk.KEY_c]: () => list.get_row_at_index(1)?.activate(), // copy 2nd recent entry
    [Gdk.KEY_e]: () => withFile(notVideo, (f) => execAsync(['swappy', '-f', f])),
    [Gdk.KEY_g]: () => withFile(null, (f) => execAsync(['gthumb', f])),
    [Gdk.KEY_m]: () => withFile(videoExts, openCompress),
    [Gdk.KEY_n]: () => withFile(null, showInFileManager),
    [Gdk.KEY_w]: () => { // wipe clipboard history
        execAsync(['bash', '-c', `cliphist wipe && rm -rf ${cacheDir}/* && mkdir -p ${cacheDir}`]);
        hide();
    },
};

const handleKeys = (_ctrl: any, key: number) => {
    const action = actions[key];
    action?.();
    return !!action;
};

export default () => inputControl('clipboard', () =>
    <BackgroundSection
        width={500}
        header={<label $type="overlay" label="Clipboard"/>}
        content={
        <scrolledwindow
            cssClasses={['clipboardScroll']}
            hscrollbarPolicy={Gtk.PolicyType.NEVER}
            vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
            overlayScrolling
            maxContentHeight={500}
            propagateNaturalHeight
        >
            {list}
        </scrolledwindow>}
    />,
    {
        onShow: () => {
            focusTop();
            refreshItems().then(focusTop);
        },
        onKeyPressed: handleKeys,
    });
