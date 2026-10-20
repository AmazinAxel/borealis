import { createState } from 'ags';
import { execAsync } from 'ags/process';
import AstalIO from 'gi://AstalIO';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Battery from 'gi://AstalBattery';
import { notifySend } from '../../lib/notifySend';
import { copyUri } from '../../lib/clipboard';

const captureDir = '/home/alec/Videos/Captures';
const clipsDir = '/home/alec/Videos/Clips';
const quote = GLib.shell_quote;

const now = () => GLib.DateTime.new_now_local().format('%Y-%m-%d_%H-%M-%S');

export const [ isRec, setIsRec ] = createState(false);
export const [ recMic, setRecMic ] = createState(false);
export const [ recQuality, setRecQuality ] = createState('Ultra');

let rec: AstalIO.Process | null = null;
let file: string;

const getFocusedMonitor = () => execAsync(['swaymsg', '-t', 'get_outputs', '-r'])
  .then((out) => (JSON.parse(out) as { focused: boolean, name: string }[]).find((o) => o.focused)!.name);

let clipper: AstalIO.Process | null = null;
let clipperGen = 0;

const stopClipper = () => {
  clipperGen++;
  clipper?.signal(2);
  clipper = null;
};

const battery = Battery.get_default();
const onBattery = () => battery.state == Battery.State.DISCHARGING;
battery.connect('notify::state', () => {
  if (onBattery()) stopClipper();
  else if (!clipper && !isRec.peek()) startClippingService();
});

export const startClippingService = (): Promise<void> => {
  stopClipper();
  const gen = clipperGen;
  if (onBattery()) return Promise.resolve();

  return getFocusedMonitor().then((monitor) => {
    if (gen != clipperGen || isRec.peek()) return;
    const p = AstalIO.Process.subprocessv(['gpu-screen-recorder', '-a', 'default_output|default_input',
      '-q', 'medium', '-w', monitor, '-o', `${clipsDir}/`, '-f', '30', '-r', '30', '-c', 'mp4']);
    clipper = p;
    p.connect('exit', () => {
      if (clipper != p) return;
      clipper = null;
      GLib.timeout_add(GLib.PRIORITY_DEFAULT, 5000, () => {
        if (gen == clipperGen && !isRec.peek()) startClippingService();
        return GLib.SOURCE_REMOVE;
      });
    });
  }).catch(() => { });
};

export const startRec = () => {
  stopClipper(); // Stops screen clipping, otherwise exits

  file = `${captureDir}/${now()}.mp4`;
  const audio = recMic.peek() ? 'default_output|default_input' : 'default_output';

  setIsRec(true);

  getFocusedMonitor().then((monitor) => {
    if (!isRec.peek()) return;
    rec = AstalIO.Process.subprocessv(['gpu-screen-recorder', '-a', audio,
      '-q', recQuality.peek().toLowerCase(), '-w', monitor, '-o', file]);
  }).catch(() => setIsRec(false));
};

let savingClip = false;
const clipsMonitor = Gio.File.new_for_path(clipsDir).monitor_directory(Gio.FileMonitorFlags.NONE, null);
clipsMonitor.connect('changed', (_, changed, _other, event) => {
  const path = changed.get_path();
  if (!savingClip || event != Gio.FileMonitorEvent.CHANGES_DONE_HINT || !path?.endsWith('.mp4')) return;
  savingClip = false;
  copyUri(path);
});

export const saveClip = () => {
  if (!clipper) return startClippingService();
  savingClip = true;
  clipper.signal(10);
};

export const stopRec = () => {
  rec?.signal(2); // Send SIGINT to stop recording
  rec = null;
  setIsRec(false);

  notifySend({
    appName: 'Recording',
    title: 'Screen recording saved',
    actions: [
      { id: 1, label: 'Open Captures', command: `nemo ${quote(captureDir)}` },
      { id: 2, label: 'View', command: `xdg-open ${quote(file)}` },
    ],
  });

  copyUri(file);

  startClippingService(); // Restart screen clipping
};
