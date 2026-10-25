import { Gtk } from 'ags/gtk4';
import Auth from 'gi://AstalAuth';
import SessionLock from 'gi://Gtk4SessionLock';
import Gdk from 'gi://Gdk';
import GLib from 'gi://GLib';
import { swayCommand } from '../../lib/sway';
import { createState, createRoot } from 'ags';
import { wallpaperTexture, randomWallpaper } from '../../lib/wallpaper';
import { formatNow } from '../../lib/time';
import { powerKeys, reboot } from '../../lib/power';
import { type Actions } from '../../lib/inputControl';
import { sleeping, inhibitSleep, releaseSleep } from '../../lib/logind';
import app from 'ags/gtk4/app';
import { timeout, type Timer } from 'ags/time';

const [ authFailed, setAuthFailed ] = createState<'' | 'failed' | 'fprintFailed'>('');
const entries = new Set<Gtk.Entry>();
export const [ locked, setLocked ] = createState(false);
const hiddenCursor = Gdk.Cursor.new_from_name('none', null);

let busy = false;
let failures = 0;
let displayOff = false;
let displayOffOnLock = false;
let afterLock: (() => void) | null = null;

const setDisplay = (on: boolean) => {
  displayOff = !on;
  swayCommand(`output * power ${on ? 'on' : 'off'}`);
};

const checkLogin = (entry: Gtk.Entry) => {
  if (busy) return;
  busy = true;
  const password = entry.get_text();
  entry.set_text('');

  Auth.Pam.authenticate(password, (_, task) => {
    try {
      Auth.Pam.authenticate_finish(task);
      unlockScreen(true);
      failures = 0;
    } catch { // Wrong password
      if (++failures >= 5) return reboot();
      setAuthFailed('failed');
    } finally {
      busy = false;
    }
  });
};

const lockKeys: Actions = {
  ...powerKeys,
  [Gdk.KEY_d]: () => setDisplay(false),
  [Gdk.KEY_c]: () => { }, // clear input
};

const handleKeys = (entry: Gtk.Entry, key: number, state: Gdk.ModifierType) => {
  if (displayOff) {
    setDisplay(true);
    return true;
  }
  if (key == Gdk.KEY_Insert) return true;
  if (!(state & Gdk.ModifierType.CONTROL_MASK)) return false;

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
        <Gtk.Picture paintable={wallpaperTexture.peek()} contentFit={Gtk.ContentFit.COVER} />
        <entry
          hexpand
          vexpand
          visibility={false}
          invisibleChar={0}
          onActivate={checkLogin}
          onChanged={() => setAuthFailed('')}
          onMap={(self) => self.grab_focus()}
          $type="overlay"
          onDestroy={(self) => entries.delete(self)}
          $={(self) => entries.add(entry = self)}
        />
        <label
          $type="overlay"
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          canTarget={false}
          useMarkup
          label={formatNow('%H\n%M')((t) => `<span line_height="0.75">${t}</span>`)}
          cssClasses={authFailed((v) => v ? [v] : [])}
        />
        <box hexpand vexpand cursor={hiddenCursor} $type="overlay" />
      </overlay>
    </Gtk.Window> as Gtk.Window;
    lock.assign_window_to_monitor(win, monitor);
  });

const lock = SessionLock.Instance.new();
lock.connect('monitor', (_, monitor: Gdk.Monitor) => assignLockWindow(monitor));
lock.connect('locked', () => {
  setLocked(true);
  if (sleeping.peek()) releaseSleep();
  if (displayOffOnLock) setDisplay(false);
  displayOffOnLock = false;
  app.get_window('powermenu')?.set_visible(false);
  afterLock?.();
  afterLock = null;
  // move cursor up a pixel so that it updates and disappears
  swayCommand('seat - cursor move 1 1, seat - cursor move -1 -1');
});
lock.connect('unlocked', () => {
  setLocked(false);
  setAuthFailed('');
});
lock.connect('failed', () => {
  setLocked(false);
  displayOffOnLock = false;
  afterLock = null;
  if (sleeping.peek()) releaseSleep();
});

export const lockScreen = () => lock.lock();
export const lockDisplayOff = () => {
  displayOffOnLock = true;
  lockScreen();
};
export const lockThen = (action: () => void) => {
  afterLock = action;
  lockScreen();
};
const unlockScreen = async (newWallpaper = false) => {
  const win = app.get_window('focusMenu');
  if (newWallpaper) await randomWallpaper();
  if (!win || (win.visible && !newWallpaper)) return lock.unlock();
  const wins = [win, ...(newWallpaper ? app.get_windows().filter((w) => w.name == 'wallpaper') : [])];
  let pending = wins.length;
  for (const w of wins) {
    w.set_visible(false);
    w.set_visible(true);
    const clock = w.get_frame_clock()!;
    const id = clock.connect('after-paint', () => {
      clock.disconnect(id);
      if (--pending) return;
      w.get_display().sync();
      lock.unlock();
    });
    w.queue_draw();
  }
};

if (GLib.file_test('/etc/pam.d/astal-fprint', GLib.FileTest.EXISTS)) {
  const fprint = new Auth.Pam({ service: 'astal-fprint' });
  const skip = () => fprint.supply_secret(null);
  let fprintFlash: Timer | null = null;
  const retry = () => lock.is_locked() && fprint.start_authenticate();
  fprint.connect('auth-info', skip);
  fprint.connect('auth-error', () => {
    for (const entry of entries) entry.set_text('');
    setAuthFailed('fprintFailed');
    fprintFlash?.cancel();
    fprintFlash = timeout(400, () => authFailed.peek() == 'fprintFailed' && setAuthFailed(''));
    skip();
  });
  fprint.connect('success', () => lock.is_locked() && unlockScreen());
  fprint.connect('fail', retry);
  lock.connect('locked', retry);
}

const inhibitReason = 'Lock screen before sleep';
inhibitSleep(inhibitReason);
sleeping.subscribe(() => {
  if (!sleeping.peek()) inhibitSleep(inhibitReason);
  else if (lock.is_locked()) releaseSleep();
  else lockScreen();
});
