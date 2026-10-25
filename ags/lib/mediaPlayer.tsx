import { Gtk } from 'ags/gtk4';
import scrollStep from './scrollStep';
import { createState } from 'ags';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import { openSocket, readLine, type Sock } from './socket';

export type MusicAction = 'next' | 'prev';

// These playlists match with the folder names in ~/Music
const playlists = ['Study', 'Focus', 'Synthwave', 'Liked', 'SynthAmbient', 'Ambient'];

export const [ isPlaying, setIsPlaying ] = createState(false);
const [ playlistIndex, setPlaylistIndex ] = createState(0);
export const playlistClass = playlistIndex((i) => playlists[i].toLowerCase());

const address = Gio.NetworkAddress.new(GLib.getenv('MPD_HOST') || '127.0.0.1', Number(GLib.getenv('MPD_PORT')) || 6600);
const encoder = new TextEncoder();
let sock: Sock | null = null;
let queue: Promise<unknown> = Promise.resolve();

const send = async (cmd: string) => {
  if (!sock) {
    sock = openSocket(address);
    await readLine(sock.input);
  }
  sock.write(encoder.encode(cmd + '\n'));
  const lines: string[] = [];
  for (let line = await readLine(sock.input); line != 'OK'; line = await readLine(sock.input)) {
    if (line.startsWith('ACK')) return lines;
    lines.push(line);
  }
  return lines;
};

const mpd = (...cmds: string[]) => {
  const p = queue.then(async () => {
    let lines: string[] = [];
    for (const cmd of cmds) {
      try {
        lines = await send(cmd);
      } catch {
        sock?.conn.close(null);
        sock = null;
        lines = await send(cmd);
      }
    }
    return lines;
  });
  queue = p.catch(() => { });
  return p.catch(() => [] as string[]);
};

const status = async () => Object.fromEntries((await mpd('status')).map((l) => l.split(': ')));

const loadPlaylist = () => mpd('clear', `add "${playlists[playlistIndex.peek()]}"`, 'shuffle');

export const updTrack = (direction: MusicAction) => {
  mpd(direction == 'next' ? 'next' : 'previous', 'play');
  setIsPlaying(true);
};

export const playPause = () => {
  status().then((s) => mpd(s.state == 'play' ? 'pause 1' : 'play'));
  setIsPlaying(!isPlaying.peek());
};

export const chngPlaylist = (direction: MusicAction) => {
  const n = playlists.length;
  setPlaylistIndex((playlistIndex.peek() + (direction == 'next' ? 1 : n - 1)) % n);
  mpd('pause 1');
  setIsPlaying(false);
  loadPlaylist();
  playPause();
};

export const initMedia = () => {
  mpd('crossfade 2');
  loadPlaylist();
};

let scrollAcc = 0;
export const mediaScroll = (self: Gtk.EventControllerScroll, _dx: number, dy: number) => {
  scrollAcc -= scrollStep(self, dy, 5, 0.2);
  const n = Math.trunc(scrollAcc);
  if (!n) return;
  scrollAcc -= n;
  mpd(`volume ${n}`);
};

export const Media = () =>
  <box name="mediaBtn">
    <image iconName={isPlaying((v) => v ? 'media-playback-pause-symbolic' : 'media-playback-start-symbolic')} />
  </box>;
