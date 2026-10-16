import { Gtk } from 'ags/gtk4';
import Auth from 'gi://AstalAuth';
import SessionLock from 'gi://Gtk4SessionLock';
import GLib from 'gi://GLib';
import Gdk from 'gi://Gdk';
import { createPoll, timeout } from 'ags/time';
import { execAsync } from 'ags/process';
import { createState, createRoot } from 'ags';
import { wallpaperTexture, randomWallpaper } from '../../lib/mediaPlayer';

const [ authFailed, setAuthFailed ] = createState(false);
const time = createPoll('', 1000, () => GLib.DateTime.new_now_local().format('%H\n%M'));

let lock: SessionLock.Instance | null = null;
let lockWindows: Gtk.Window[] = [];
const destroyLockWindows = () => { const wins = lockWindows; lockWindows = []; timeout(100, () => wins.forEach((w) => w.destroy())); };

const hiddenCursor = Gdk.Cursor.new_from_texture( // no cursor
    Gdk.MemoryTexture.new(1, 1, Gdk.MemoryFormat.R8G8B8A8, GLib.Bytes.new(new Uint8Array([0, 0, 0, 0])), 4),
    0, 0, null,
);

let busy = false;
let failures = 0;

const checkLogin = (entry: Gtk.Entry) => {
    if (busy) return;
    busy = true;
    const password = entry.get_text();
    entry.set_text('');

    Auth.Pam.authenticate(password, (_, task) => {
        try {
            Auth.Pam.authenticate_finish(task);
            busy = false;
            failures = 0;
            unlockScreen();
            randomWallpaper();
        } catch { // Wrong password
            setAuthFailed(true);
            if (++failures >= 5) return void execAsync('systemctl reboot');
            timeout(2000, () => { setAuthFailed(false); busy = false; });
        };
    });
};

const handleKeys = (entry: Gtk.Entry, key: number, state: Gdk.ModifierType) => {
    if (key == Gdk.KEY_Insert) return true;
    if (!(state & Gdk.ModifierType.CONTROL_MASK)) return busy;

    switch (Gdk.keyval_to_lower(key)) {
        case Gdk.KEY_s: // sleep
            execAsync('systemctl suspend');
            break;
        case Gdk.KEY_h:
            execAsync('systemctl hibernate');
            break;
        case Gdk.KEY_q: // power off
            execAsync('systemctl poweroff');
            break;
        case Gdk.KEY_c: // clear input
            break;
        case Gdk.KEY_v: // no paste from clipboard!
            return true;
        default: return false;
    };

    entry.set_text(''); // wipe anything typed
    return true;
};

const assignLockWindow = (monitor: Gdk.Monitor) =>
    createRoot((dispose) => {
        let entry: Gtk.Entry;
        const win = <Gtk.Window name="lockscreen" cursor={hiddenCursor} onDestroy={dispose}>
            <overlay>
                <Gtk.EventControllerKey
                    propagationPhase={Gtk.PropagationPhase.CAPTURE}
                    onKeyPressed={(_ctrl, key, _keycode, state) => handleKeys(entry, key, state)}
                />
                <Gtk.Picture paintable={wallpaperTexture} contentFit={Gtk.ContentFit.COVER} />
                <entry
                    hexpand
                    vexpand
                    visibility={false}
                    invisibleChar={0}
                    onActivate={checkLogin}
                    onMap={(self) => self.grab_focus()}
                    $type="overlay"
                    $={(self) => entry = self}
                />
                <label
                    halign={Gtk.Align.CENTER}
                    valign={Gtk.Align.CENTER}
                    useMarkup={true}
                    label={time((t) =>  `<span line_height="0.75">${t}</span>`)}
                    css_classes={authFailed((v) => v ? ['failed'] : [])}
                    canTarget={false}
                    $type="overlay"
                />
                <box
                    hexpand
                    vexpand
                    cursor={hiddenCursor}
                    $type="overlay"
                />
            </overlay>
        </Gtk.Window> as Gtk.Window;
        lockWindows.push(win);
        lock!.assign_window_to_monitor(win, monitor);
    });

export const lockScreen = () => {
    if (lock) return; // Already locked?

    lock = SessionLock.Instance.new();
    lock.connect('failed', () => { lock = null; destroyLockWindows(); });
    lock.connect('unlocked', () => { lock = null; destroyLockWindows(); });

    lock.connect('monitor', (_, monitor: Gdk.Monitor) => assignLockWindow(monitor));

    if (!lock.lock()) return void (lock = null);

    // move cursor up a pixel so that it updates and disappears
    timeout(120, () => execAsync('swaymsg -- seat - cursor move 1 1, seat - cursor move -1 -1').catch(() => {}));
};

export const unlockScreen = () => {
    lock?.unlock();
    destroyLockWindows();
    lock = null;
};
