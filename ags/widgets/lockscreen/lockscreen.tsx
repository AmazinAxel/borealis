import { Gtk } from 'ags/gtk4';
import Auth from 'gi://AstalAuth';
import SessionLock from 'gi://Gtk4SessionLock';
import Gdk from 'gi://Gdk';
import { timeout } from 'ags/time';
import { execAsync } from 'ags/process';
import { createState, createRoot } from 'ags';
import { wallpaperTexture, randomWallpaper } from '../../lib/wallpaper';
import { formatNow } from '../../lib/time';
import { suspend, hibernate, poweroff, reboot } from '../../lib/power';
import { sleeping, inhibitSleep, releaseSleep } from '../../lib/logind';

const [ authFailed, setAuthFailed ] = createState(false);
const hiddenCursor = Gdk.Cursor.new_from_name('none', null);

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
      if (++failures >= 5) return reboot();
      timeout(2000, () => {
        setAuthFailed(false);
        busy = false;
      });
    }
  });
};

const lockKeys: Record<number, () => void> = {
  [Gdk.KEY_s]: suspend,
  [Gdk.KEY_h]: hibernate,
  [Gdk.KEY_q]: poweroff,
  [Gdk.KEY_c]: () => { }, // clear input
};

const handleKeys = (entry: Gtk.Entry, key: number, state: Gdk.ModifierType) => {
  if (key == Gdk.KEY_Insert) return true;
  if (!(state & Gdk.ModifierType.CONTROL_MASK)) return busy;

  const lower = Gdk.keyval_to_lower(key);
  if (lower == Gdk.KEY_v) return true; // no paste from clipboard!
  const action = lockKeys[lower];
  if (!action) return false;

  action();
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
          $type="overlay"
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          canTarget={false}
          useMarkup
          label={formatNow('%H\n%M')((t) => `<span line_height="0.75">${t}</span>`)}
          cssClasses={authFailed((v) => v ? ['failed'] : [])}
        />
        <box hexpand vexpand cursor={hiddenCursor} $type="overlay" />
      </overlay>
    </Gtk.Window> as Gtk.Window;
    lock.assign_window_to_monitor(win, monitor);
  });

const lock = SessionLock.Instance.new();
lock.connect('monitor', (_, monitor: Gdk.Monitor) => assignLockWindow(monitor));
lock.connect('locked', () => {
  if (sleeping.peek()) releaseSleep();
  // move cursor up a pixel so that it updates and disappears
  execAsync('swaymsg -- seat - cursor move 1 1, seat - cursor move -1 -1').catch(() => { });
});
lock.connect('failed', () => sleeping.peek() && releaseSleep());

export const lockScreen = () => lock.lock();
const unlockScreen = () => lock.unlock();

const inhibitReason = 'Lock screen before sleep';
inhibitSleep(inhibitReason);
sleeping.subscribe(() => {
  if (!sleeping.peek()) inhibitSleep(inhibitReason);
  else if (lock.is_locked()) releaseSleep();
  else lockScreen();
});
