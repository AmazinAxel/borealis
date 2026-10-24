import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { createState } from 'ags';
import perMonitor from '../lib/perMonitor';
import BackgroundSection from '../lib/backgroundSection';
import inputControl from '../lib/inputControl';
import { interval, timeout, type Timer } from 'ags/time';
import { execAsync } from 'ags/process';
import { swayCommand } from '../lib/sway';
import { notifySend } from '../lib/notifySend';

const { TOP } = Astal.WindowAnchor;
let textBox: Gtk.Entry;

export const [ focusText, setFocusText ] = createState('');
export const focus = focusText(Boolean);

const [ breakWait, setBreakWait ] = createState(-1);
let breakTimers: Timer[] = [];

const endBreak = () => {
  breakTimers.forEach((t) => t.cancel());
  breakTimers = [];
  setBreakWait(-1);
};

export const cancelBreak = () => breakWait.peek() >= 0 && endBreak();

export const startBreak = (cmd: string) => {
  if (breakTimers.length) return;
  const start = Date.now();
  setBreakWait(0);
  breakTimers = [interval(100, () => {
    const waited = (Date.now() - start) / 10000;
    if (waited < 1) return setBreakWait(waited);
    endBreak();
    const unit = `focus-break-${start}`;
    swayCommand(`exec systemd-run --user --scope --collect --unit=${unit} ${cmd}`);
    breakTimers = [
      timeout(105000, () => notifySend({ appName: 'Focus', title: 'App closing in 15s' })),
      timeout(120000, () => {
        endBreak();
        execAsync(['systemctl', '--user', 'stop', `${unit}.scope`]).catch(() => { });
      }),
    ];
  })];
};

export const toggleFocus = () => {
  if (breakTimers.length) return;
  focus.peek() ? setFocusText('') : app.toggle_window('focusMenu');
};

const startFocus = () => {
  const text = textBox.text.trim();
  if (!text) return;
  setFocusText(text);
  app.get_window('focusMenu')?.set_visible(false);
};

export const focusMenu = () => inputControl('focusMenu', () =>
  <BackgroundSection
    width={400}
    header={<entry
      $type="overlay"
      primaryIconName="emoji-flags-symbolic"
      placeholderText="Task"
      maxLength={60}
      onActivate={startFocus}
      $={(self) => textBox = self} />} />,
  { searchable: true, focus: () => textBox });

export const focusTask = () => perMonitor((monitor) =>
  <window
    name="focusTask"
    namespace="focusTask"
    anchor={TOP} // fullscreen cant cover this!!
    layer={Astal.Layer.TOP}
    gdkmonitor={monitor}
    application={app}
    visible={focus}
  >
    <box orientation={Gtk.Orientation.VERTICAL}>
      <label cssClasses={['statusElement']} label={focusText} />
      <levelbar value={breakWait} visible={breakWait((w) => w >= 0)} />
    </box>
  </window>);
