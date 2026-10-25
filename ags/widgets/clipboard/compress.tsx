import { createState } from 'ags';
import { execAsync } from 'ags/process';
import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import GLib from 'gi://GLib';
import Gdk from 'gi://Gdk';
import AstalIO from 'gi://AstalIO';
import BackgroundSection from '../../lib/backgroundSection';
import perMonitor from '../../lib/perMonitor';
import inputControl, { type Actions } from '../../lib/inputControl';
import { notifySend } from '../../lib/notifySend';
import { copyUri } from '../../lib/clipboard';
import { tmpDir } from './clipboardItem';

const targets = [10, 20, 50, 100, 500]; // MB
const [ target, setTarget ] = createState(0);
const [ progress, setProgress ] = createState(-1);
let source = '';
let entryId = '';

const ffmpeg = (args: string[], duration: number) => new Promise<void>((resolve, reject) => {
  let err = '';
  const p = AstalIO.Process.subprocessv(['ffmpeg', '-v', 'error', '-nostats', '-stats_period', '0.1', '-progress', 'pipe:1', '-y', ...args]);
  p.connect('stdout', (_, line) => {
    const us = line.startsWith('out_time_us=') ? parseInt(line.slice(12)) : NaN;
    if (us >= 0) setProgress(Math.min(us / duration, 1));
  });
  p.connect('stderr', (_, line) => err += line + '\n');
  p.connect('exit', (_, code) => code ? reject(err.trim()) : resolve());
});

const compress = async () => {
  if (progress.peek() >= 0) return;
  setProgress(0);
  app.get_window('compress')?.set_visible(false);

  const limit = targets[target.peek()];
  const base = GLib.path_get_basename(source).replace(/\.[^.]*$/, '');
  const out = `${tmpDir}/${base == entryId ? base : base + '_' + entryId}.mp4`;

  try {
    const duration = parseFloat(await execAsync(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', source]));
    const vb = Math.max(Math.round(limit * 7600000 / duration - 128000), 100000);
    await ffmpeg(['-i', source, '-c:v', 'libx264', '-preset', 'veryfast', '-b:v', `${vb}`, '-maxrate', `${vb}`, '-bufsize', `${vb * 2}`,
      '-c:a', 'aac', '-b:a', '128k', '-movflags', '+faststart', out], duration * 1e6);
    copyUri(out);
  } catch (err) {
    notifySend({ appName: 'Compress', title: 'Compression failed', body: String(err) });
  } finally {
    setProgress(-1);
  }
};

export const openCompress = (file: string, id: string) => {
  if (progress.peek() >= 0) return;
  source = file;
  entryId = id;
  setTarget(0);
  app.get_window('compress')?.set_visible(true);
};

const actions: Actions = {
  [Gdk.KEY_Tab]: () => setTarget((target.peek() + 1) % targets.length), // change size
  [Gdk.KEY_Return]: compress, // compress!!
};

export default () => inputControl('compress', () =>
  <BackgroundSection
    height={100} width={350}
    header={<label $type="overlay" hexpand vexpand
      halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}
      label={target((t) => `${targets[t]}MB`)} />}
  />,
  { actions });

const { BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

export const compressProgress = () => perMonitor((monitor) =>
  <window
    name="compressProgress"
    namespace="compressProgress"
    anchor={BOTTOM | LEFT | RIGHT}
    layer={Astal.Layer.OVERLAY}
    gdkmonitor={monitor}
    application={app}
    canTarget={false}
    visible={progress((p) => p >= 0 && p < 0.99)}
  >
    <levelbar value={progress((p) => Math.max(p, 0))} />
  </window>);
