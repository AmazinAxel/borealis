import { createState } from 'ags';
import { execAsync } from 'ags/process';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import GLib from 'gi://GLib';
import Gdk from 'gi://Gdk';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl, { type Actions } from '../../lib/inputControl';
import { notifySend } from '../../lib/notifySend';
import { copyUri } from '../../lib/clipboard';
import { tmpDir } from './clipboardItem';

const targets = [10, 20, 50, 100, 500]; // MB
const quote = GLib.shell_quote;

const [ target, setTarget ] = createState(0);
let source = '';
let entryId = '';

const script = (input: string, out: string, limit: number) => {
  const i = quote(input);

  return [
    `d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 ${i})`,
    `vb=$(awk -v d="$d" 'BEGIN { v = ${limit} * 7600000 / d - 128000; printf "%d", (v > 100000) ? v : 100000 }')`,
    `ffmpeg -v error -y -i ${i} -c:v libx264 -preset veryfast -b:v "$vb" -maxrate "$vb" -bufsize "$((vb * 2))"`
    + ` -c:a aac -b:a 128k -movflags +faststart ${quote(out)}`
  ].join(' && \\\n');
};

const compress = async () => {
  const limit = targets[target.peek()];

  const base = GLib.path_get_basename(source).replace(/\.[^.]*$/, '');
  const out = `${tmpDir}/${base == entryId ? base : base + '_' + entryId}.mp4`;

  app.get_window('compress')?.set_visible(false);

  try {
    await execAsync(['bash', '-c', script(source, out, limit)]);
  } catch (err) {
    notifySend({ appName: 'Compress', title: 'Compression failed', body: String(err) });
    return;
  }

  copyUri(out);
  notifySend({
    appName: 'Compress',
    title: 'Compression done',
    actions: [{ id: 1, label: 'View', command: 'xdg-open ' + quote(out) }]
  });
};

export const openCompress = (file: string, id: string) => {
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
