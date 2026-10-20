import { execAsync } from 'ags/process';
import { Gtk } from 'ags/gtk4';
import { createState } from 'ags';
import app from 'ags/gtk4/app';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Gdk from 'gi://Gdk';
import { ClipboardItem, entryPath, cacheDir, videoExts, binaryData } from './clipboardItem';
import { openCompress } from './compress';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';
import { streamingMode } from '../../lib/streamingMode';

const hide = () => app.get_window('clipboard')?.hide();
const items = new Map<string, { mime: string, path: string | null, search: string, child: Gtk.Widget }>();
const [ hasResults, setHasResults ] = createState(false);

let textBox: Gtk.Entry;
let query = '';

const list = new Gtk.ListBox({ canTarget: false });
list.set_filter_func((row) => !query || !!items.get(row.child!.name)?.search.includes(query));
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
    .filter(([ id, content ]) => id && content);

  entries.forEach(([ id, content ]) => {
    if (items.has(id)) return;

    const image = content.match(binaryData);
    const path = entryPath(id, content);
    const child = ClipboardItem(id, content, path, image) as Gtk.Widget;
    list.append(child);

    items.set(id, {
      path, child, search: (image ? 'image ' : '') + content.toLowerCase(), mime:
        image ? `image/${image[1]}`
          : content.trim().startsWith('file://') ? 'text/uri-list' // paste the ACTUAL file
            : 'text/plain'
    });
  });

  const current = new Set(entries.map(([ id ]) => id));
  const stale = [...items].filter(([ id ]) => !current.has(id));

  stale.forEach(([ id, { child } ]) => {
    list.remove(child.get_parent() as Gtk.Widget); // ListBoxRow parent
    items.delete(id);
  });

  // Their decodes and thumbnails are dead weight now
  if (stale.length) execAsync(['bash', '-c',
    'rm -f ' + stale.map(([ id ]) => `${cacheDir}/${id}.*`).join(' ')]);
  selectTop();
}).catch(() => { });
refreshItems();

const cliphistDb = Gio.File.new_for_path(`${GLib.get_user_cache_dir()}/cliphist/db`).monitor_file(Gio.FileMonitorFlags.NONE, null);
cliphistDb.connect('changed', (_, _file, _other, event) => event == Gio.FileMonitorEvent.CHANGES_DONE_HINT && refreshItems());

const visibleRows = () => {
  const rows: Gtk.ListBoxRow[] = [];
  for (let i = 0, row; (row = list.get_row_at_index(i)); i++)
    if (row.get_child_visible()) rows.push(row);
  return rows;
};

const select = (row?: Gtk.ListBoxRow) => {
  list.select_row(row ?? null);
  if (row) (row.get_ancestor(Gtk.Viewport.$gtype) as Gtk.Viewport | null)?.scroll_to(row, null);
};

const selectTop = () => {
  const rows = visibleRows();
  setHasResults(rows.length > 0);
  select(rows[0]);
};

const moveSelection = (delta: number) => {
  const rows = visibleRows();
  const i = rows.indexOf(list.get_selected_row()!) + delta;
  select(rows[Math.max(0, Math.min(rows.length - 1, i))]);
};

const search = (text: string) => {
  query = text.toLowerCase();
  list.invalidate_filter();
  selectTop();
};

const selectedRow = () => list.get_selected_row() ?? visibleRows()[0];
const selectedId = () => selectedRow()?.child?.name ?? '';

const showInFileManager = (file: string) => Gio.DBus.session.call(
  'org.freedesktop.FileManager1',
  '/org/freedesktop/FileManager1',
  'org.freedesktop.FileManager1',
  'ShowItems',
  new GLib.Variant('(ass)', [[GLib.filename_to_uri(file, null)], '']),
  null, Gio.DBusCallFlags.NONE, -1, null, null);

// streaming mode skips thumbnails, so image entries have no decode on disk yet
const withFile = (want: ((f: string) => boolean) | null, action: (file: string, id: string) => void) => {
  const id = selectedId();
  const { path, mime } = items.get(id) ?? {};
  if (!path || (want && !want(path))) return;

  const run = () => {
    if (!GLib.file_test(path, GLib.FileTest.EXISTS)) return;
    hide();
    action(path, id);
  };

  if (GLib.file_test(path, GLib.FileTest.EXISTS) || !mime?.startsWith('image/')) return run();

  execAsync(['bash', '-c', `cliphist decode ${id} > ${path}`]).then(run).catch(() => { });
};

const actions: Record<number, () => void> = {
  [Gdk.KEY_c]: () => visibleRows()[1]?.activate(), // copy 2nd recent entry
  [Gdk.KEY_e]: () => withFile((f) => !videoExts.test(f), (f) => execAsync(['swappy', '-f', f])),
  [Gdk.KEY_g]: () => withFile(null, (f) => execAsync(['gthumb', f])),
  [Gdk.KEY_m]: () => withFile((f) => videoExts.test(f), openCompress),
  [Gdk.KEY_n]: () => withFile(null, showInFileManager),
  [Gdk.KEY_w]: () => { // wipe clipboard history
    execAsync(['bash', '-c', `cliphist wipe && rm -rf ${cacheDir}/* && mkdir -p ${cacheDir}`]);
    hide();
  },
};

const handleKeys = (_ctrl: Gtk.EventControllerKey, key: number, _keycode: number, state: Gdk.ModifierType) => {
  if (key == Gdk.KEY_Return) {
    selectedRow()?.activate();
    return true;
  }
  if (key == Gdk.KEY_Up || key == Gdk.KEY_Down) {
    moveSelection(key == Gdk.KEY_Down ? 1 : -1);
    return true;
  }
  const action = (state & Gdk.ModifierType.CONTROL_MASK) ? actions[Gdk.keyval_to_lower(key)] : undefined;
  action?.();
  return !!action;
};

export default () => inputControl('clipboard', () =>
  <BackgroundSection
    height={700} width={500}
    header={<entry
      $type="overlay"
      primaryIconName="edit-paste-symbolic"
      placeholderText="Clipboard"
      onNotifyText={({ text }) => search(text)}
      $={(self) => textBox = self} />}
    content={
      <scrolledwindow
        cssClasses={['clipboardScroll']}
        visible={hasResults}
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
      textBox.text = '';
      selectTop();
      refreshItems();
    },
    onKeyPressed: handleKeys,
    searchable: true,
    focus: () => textBox,
  });
