import GLib from 'gi://GLib';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { createState, For } from 'ags';
import { execAsync } from 'ags/process';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';

const STORE = `${GLib.get_home_dir()}/.password-store`;

let textBox: Gtk.Entry;
let entries: string[] = [];
const [ results, setResults ] = createState(new Array<string>());

const loadEntries = async () => {
    const out = await execAsync(['bash', '-c',
        `cd "${STORE}" 2>/dev/null && find . -type f -name '*.gpg' | sed 's|^\\./||; s|\\.gpg$||' | sort`
    ]).catch(() => '');
    entries = out.split('\n').filter(Boolean);
};

const search = (q: string) => {
    if (q.length < 2) return setResults([]);
    const ql = q.toLowerCase();
    const matched = entries
        .map(n => [n, n.toLowerCase().indexOf(ql)] as const)
        .filter(([, s]) => s >= 0)
        .sort((a, b) => a[1] - b[1])
        .slice(0, 5)
        .map(([n]) => n);
    setResults(matched);
};

const copyPair = async (name: string) => {
    app.get_window('pass')?.set_visible(false);
    const fallback = name.includes('/') ? name.slice(name.lastIndexOf('/') + 1) : name;
    const userCmd = `u=$(pass show "$1" | sed -n '2p' | sed -E 's/^[[:space:]]*(login|username|user|email):[[:space:]]*//I' | tr -d '\\n'); [ -z "$u" ] && u=${GLib.shell_quote(fallback)}; printf '%s' "$u" | wl-copy -n -t text/plain`;
    const passCmd = `pass show "$1" | head -n1 | tr -d '\\n' | wl-copy -n -t text/plain`;
    await execAsync(['bash', '-c', `${userCmd} && sleep 0.15 && ${passCmd}`, 'bash', name]);
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
            $={self => { textBox = self; }}
        />}
        content={<box spacing={6} orientation={Gtk.Orientation.VERTICAL}>
            <For each={results}>
                {(name) =>
                    <button onClicked={() => copyPair(name)} cssClasses={['button']}>
                        <label cssClasses={['name']} xalign={0} valign={Gtk.Align.CENTER} label={name}/>
                    </button>
                }
            </For>
        </box>}
    />,
    {
        onShow: () => { textBox.text = ''; setResults([]); loadEntries(); },
        searchable: true,
        focus: () => textBox,
    }
);
