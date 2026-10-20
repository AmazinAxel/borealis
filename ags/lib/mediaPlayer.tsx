import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import { execAsync } from 'ags/process';
import { createState } from 'ags';

export type MusicAction = 'next' | 'prev';

// These playlists match with the folder names in ~/Music
const playlists = ['Study', 'Focus', 'Synthwave', 'Liked', 'SynthAmbient', 'Ambient'];

export const [ isPlaying, setIsPlaying ] = createState(false);
const [ playlistIndex, setPlaylistIndex ] = createState(0);
export const playlistClass = playlistIndex((i) => playlists[i].toLowerCase());

let mpcQueue: Promise<unknown> = Promise.resolve();
const mpc = (...args: string[][]) => {
  for (const a of args)
    mpcQueue = mpcQueue.then(() => execAsync(['mpc', ...a]).catch(() => { }));
};

const loadPlaylist = () => mpc(['clear'], ['add', `${playlists[playlistIndex.peek()]}/`], ['shuffle']);

export const updTrack = (direction: MusicAction) => {
  mpc(['pause'], [direction], ['play']);
  setIsPlaying(true);
};

export const playPause = () => {
  mpc(['toggle']);
  setIsPlaying(!isPlaying.peek());
};

export const chngPlaylist = (direction: MusicAction) => {
  const n = playlists.length;
  setPlaylistIndex((playlistIndex.peek() + (direction == 'next' ? 1 : n - 1)) % n);
  mpc(['pause']);
  setIsPlaying(false);
  loadPlaylist();
  playPause();
};

export const initMedia = () => {
  mpc(['crossfade', '2']);
  loadPlaylist();
};

let scrollAcc = 0;
export const Media = () =>
  <box name="mediaBtn">
    <Gtk.EventControllerScroll
      flags={Gtk.EventControllerScrollFlags.VERTICAL}
      onScroll={(self, _dx, dy) => {
        scrollAcc -= self.get_unit() == Gdk.ScrollUnit.WHEEL ? Math.sign(dy) * 5 : dy * 0.2;
        const n = Math.trunc(scrollAcc);
        if (!n) return;
        scrollAcc -= n;
        mpc(['volume', `${n > 0 ? '+' : ''}${n}`]);
      }}
    />
    <image iconName={isPlaying((v) => v ? 'media-playback-pause-symbolic' : 'media-playback-start-symbolic')} />
  </box>;
