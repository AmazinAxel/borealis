import GLib from 'gi://GLib';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { createState, For } from 'ags';
import { execAsync } from 'ags/process';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';
import { copyLogin } from '../../lib/clipboard';

const STORE = `${GLib.get_home_dir()}/.password-store`;

let textBox: Gtk.Entry;
let entries: string[] = [];
const [ results, setResults ] = createState<string[]>([]);

const loadEntries = async () => {
  const out = await execAsync(['find', STORE, '-type', 'f', '-name', '*.gpg']).catch(() => '');
  entries = out.split('\n').filter(Boolean).map((f) => f.slice(STORE.length + 1, -4)).sort();
};

const search = (q: string) => {
  if (q.length < 2) return setResults([]);
  const ql = q.toLowerCase();
  const matched = entries
    .map((n) => [n, n.toLowerCase().indexOf(ql)] as const)
    .filter(([ , s ]) => s >= 0)
    .sort((a, b) => a[1] - b[1])
    .slice(0, 5)
    .map(([ n ]) => n);
  setResults(matched);
};

const copyPair = async (name: string) => {
  app.get_window('pass')?.set_visible(false);
  const [ password, login = '' ] = (await execAsync(['pass', 'show', name]).catch(() => '')).split('\n');
  if (!password) return;
  const user = login.replace(/^\s*(login|username|user|email):\s*/i, '').trim() || name.split('/').pop()!;
  copyLogin(user, password);
};

loadEntries();

export default () => inputControl('pass', () =>
  <BackgroundSection
    height={700} width={500}
    header={<entry
      $type="overlay"
      primaryIconName="system-search-symbolic"
      placeholderText="Passwords"
      onNotifyText={({ text }) => search(text)}
      onActivate={() => {
        const top = results.peek()[0];
        if (top) copyPair(top);
      }}
      $={(self) => textBox = self}
    />}
    content={<box spacing={6} orientation={Gtk.Orientation.VERTICAL} visible={results((r) => r.length > 0)}>
      <For each={results}>
        {(name) =>
          <button canTarget={false} onClicked={() => copyPair(name)} cssClasses={['button']}>
            <label cssClasses={['name']} xalign={0} valign={Gtk.Align.CENTER} label={name} />
          </button>
        }
      </For>
    </box>}
  />,
  {
    onShow: () => {
      textBox.text = '';
      setResults([]);
      loadEntries();
    },
    searchable: true,
    focus: () => textBox,
  },
);
