import { Gtk } from "ags/gtk4";
import Gdk from "gi://Gdk";
import { execAsync } from 'ags/process';
import { timeout } from 'ags/time';
import { createState } from 'ags';
import AstalIO from 'gi://AstalIO';
import GdkPixbuf from 'gi://GdkPixbuf';

const themeCss = new Gtk.CssProvider();
Gtk.StyleContext.add_provider_for_display(
    Gdk.Display.get_default()!, themeCss, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

export type musicAction = 'next' | 'prev';
export const [ isPlaying, setIsPlaying ] = createState(false);
export const [ playlist, setPlaylist ] = createState(1);
export const [ playlistName, setPlaylistName ] = createState('');
export const [ wallpaperTexture, setWallpaperTexture ] = createState<Gdk.Paintable>(Gdk.Paintable.new_empty(1, 1));
export const [ wallpaperLight, setWallpaperLight ] = createState(false);

// These playlists match with the folder names in ~/Music
const playlists =      ['Study',  'Focus',  'Synthwave', 'Liked', 'SynthAmbient', 'Ambient'];
const playlistColors = ['bf616a', '5e81ac', 'b48ead',    '8fbcbb',      'ebcb8b',       '81a1c1'];

let mpcQueue: Promise<unknown> = Promise.resolve();
const mpc = (...cmds: string[]) => {
    for (const c of cmds)
        mpcQueue = mpcQueue.then(() => execAsync('mpc ' + c).catch(() => {}));
    return mpcQueue;
};

export const updTrack = (direction: musicAction) => {
    mpc('pause', direction, 'play');
    setIsPlaying(true);
};

export const playPause = () => {
    mpc('toggle');
    setIsPlaying(!isPlaying.peek());
};

let swaybg: AstalIO.Process | null = null;
let current = '';
export const randomWallpaper = async () => {
    const files = (await execAsync(['find', '/home/alec/Projects/flake/wallpapers', '-type', 'f'])).split('\n').filter((f) => f && f !== current);
    const wallpaper = current = files[Math.floor(Math.random() * files.length)];
    const old = swaybg;
    swaybg = AstalIO.Process.subprocessv(['swaybg', '-i', wallpaper, '-m', 'fill']);
    if (old) timeout(1000, () => old.kill());
    setWallpaperTexture(Gdk.Texture.new_from_filename(wallpaper));
    const [r, g, b] = GdkPixbuf.Pixbuf.new_from_file_at_scale(wallpaper, 1, 1, false).get_pixels();
    setWallpaperLight(0.299 * r + 0.587 * g + 0.114 * b > 150);
};

playlistName.subscribe(() => {
    themeCss.load_from_string(`
        #status #mediaBtn { background-color: #${playlistColors[playlist.peek() - 1]}; }
    `);
});

export const chngPlaylist = (direction: musicAction) => {
    const n = playlists.length;
    setPlaylist((playlist.peek() - 1 + (direction == 'next' ? 1 : n - 1)) % n + 1);

    // Stop playing music
    mpc('pause');
    setIsPlaying(false);

    setPlaylistName(playlists[playlist.peek() - 1]);

    // Clear the current cache and add the new playlist
    mpc('clear', `add ${playlistName.peek()}/`, 'shuffle');
    playPause(); // Start playing
};

export const initMedia = () => {
    randomWallpaper();
    setPlaylistName('Study'); // Must set to invoke binds
    mpc('crossfade 2', 'clear', `add ${playlistName.peek()}/`, 'shuffle');
};


let scrollAcc = 0
export const Media = () =>
    <box name={'mediaBtn'}>
    <Gtk.EventControllerScroll
        flags={Gtk.EventControllerScrollFlags.VERTICAL}
        onScroll={(self, __, y) => {
            scrollAcc -= self.get_unit() === Gdk.ScrollUnit.WHEEL ? Math.sign(y) * 5 : y * 0.2
            const n = Math.trunc(scrollAcc)
            if (!n) return
            scrollAcc -= n
            execAsync(`mpc volume ${n > 0 ? '+' : ''}${n}`).catch(() => {})
        }}/>
        <image iconName={isPlaying.as(
            (v: boolean) => (v) ? 'media-playback-pause-symbolic' : 'media-playback-start-symbolic')
        }/>
    </box>
