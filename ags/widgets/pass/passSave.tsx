import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import GLib from 'gi://GLib';
import { createState } from 'ags';
import app from 'ags/gtk4/app';
import { execAsync } from 'ags/process';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';
import { notifySend } from '../../lib/notifySend';

let siteBox: Gtk.Entry;
let userBox: Gtk.Entry;
let passBox: Gtk.Entry;

const [generated, setGenerated] = createState(false);

const lower = 'abcdefghijklmnopqrstuvwxyz';
const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const digits = '0123456789';
const symbols = '!@#$%^&*()-_=+[]{};:,.?';
const alphabet = lower + upper + digits + symbols;

const pick = (set: string) => set[GLib.random_int_range(0, set.length)];

const randomPassword = (length = 20) => {
    const chars = [pick(lower), pick(upper), pick(digits), pick(symbols)];
    while (chars.length < length) chars.push(pick(alphabet));
    for (let i = chars.length - 1; i > 0; i--) {
        const j = GLib.random_int_range(0, i + 1);
        [chars[i], chars[j]] = [chars[j], chars[i]];
    }
    return chars.join('');
};

const generate = () => {
    const password = randomPassword();
    passBox.text = password;
    passBox.set_position(-1);
    setGenerated(true);
    execAsync(['bash', '-c', `printf '%s' "$1" | wl-copy -n -t text/plain`, 'bash', password]);
};

const reset = () => {
    siteBox.text = '';
    userBox.text = '';
    passBox.text = '';
    setGenerated(false);
};

const save = async () => {
    const site = siteBox.text.trim();
    const user = userBox.text.trim();
    const password = passBox.text;
    if (!site || !user || !password) return;

    const body = `${password}\nlogin: ${user}\n`;
    app.get_window('passSave')?.set_visible(false);

    try {
        await execAsync(['bash', '-c', `printf '%s' "$1" | pass insert -m -f "$2"`, 'bash', body, site]);
    } catch {
        notifySend({ appName: 'Pass', title: 'Unable to save password' });
        return;
    }

    // Copy it
    await execAsync(['bash', '-c',
        `printf '%s' "$1" | wl-copy -n -t text/plain && sleep 0.15 && printf '%s' "$2" | wl-copy -n -t text/plain`,
        'bash', user, password
    ]);

    // Sync with homelab
    try {
        await execAsync(['bash', '-c',
            `pass git pull --rebase && { [ "$(pass git rev-list '@{u}..HEAD' --count)" -gt 0 ] && pass git push || true; }`
        ]);
    } catch {
        notifySend({ appName: 'Pass', title: 'Pass sync to homelab failed' });
    }
};

export default () => inputControl('passSave', () =>
    <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        <BackgroundSection
            height={300} width={400}
            header={<label $type="overlay" label="Password"/>}
            content={
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    <entry
                        $={self => siteBox = self}
                        placeholderText="Website"
                        onActivate={() => userBox.grab_focus()} // next
                    />
                    <entry
                        $={self => userBox = self}
                        placeholderText="Username"
                        onActivate={() => passBox.grab_focus()} // next
                    />
                    <box spacing={4}>
                        <entry
                            $={self => passBox = self}
                            hexpand
                            visibility={false}
                            placeholderText="Password"
                            onActivate={save} // save
                        >
                            <Gtk.EventControllerKey
                                onKeyPressed={(_ctrl, key, _keycode, state) => {
                                    if (key !== Gdk.KEY_Tab || (state & Gdk.ModifierType.SHIFT_MASK)) return false;
                                    generate();
                                    return true;
                                }}/>
                        </entry>
                        <image
                            cssClasses={generated(on => on ? ['passGenIcon', 'generated'] : ['passGenIcon'])}
                            iconName="dialog-password-symbolic"
                        />
                    </box>
                </box>
            }
        />
    </box>,
    { onShow: reset, focus: () => siteBox }
);
