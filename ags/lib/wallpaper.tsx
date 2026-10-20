import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Gdk from 'gi://Gdk';
import GdkPixbuf from 'gi://GdkPixbuf';
import Gio from 'gi://Gio';
import { createState, For, This, onCleanup } from 'ags';
import { monitors } from './monitors';

const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;
const wallpaperDir = '/home/alec/Wallpapers';

export const [ wallpaperTexture, setWallpaperTexture ] = createState<Gdk.Paintable>(Gdk.Paintable.new_empty(1, 1));
export const [ wallpaperLight, setWallpaperLight ] = createState(false);

const listFiles = (dir: string): string[] => {
  const files: string[] = [];
  try {
    const e = Gio.File.new_for_path(dir).enumerate_children('standard::name,standard::type', Gio.FileQueryInfoFlags.NONE, null);
    for (let i = e.next_file(null); i; i = e.next_file(null)) {
      const path = `${dir}/${i.get_name()}`;
      files.push(...(i.get_file_type() == Gio.FileType.DIRECTORY ? listFiles(path) : [path]));
    }
  } catch { }
  return files;
};

let current = '';
export const randomWallpaper = () => {
  const files = listFiles(wallpaperDir).filter((f) => f != current);
  if (!files.length) return;
  current = files[Math.floor(Math.random() * files.length)];
  try {
    GdkPixbuf.Pixbuf.new_from_stream_async(Gio.File.new_for_path(current).read(null), null, (_, res) => {
      try {
        const p = GdkPixbuf.Pixbuf.new_from_stream_finish(res);
        const format = p.hasAlpha ? Gdk.MemoryFormat.R8G8B8A8 : Gdk.MemoryFormat.R8G8B8;
        setWallpaperTexture(Gdk.MemoryTexture.new(p.width, p.height, format, p.read_pixel_bytes(), p.rowstride));
        const grid = p.scale_simple(16, 9, GdkPixbuf.InterpType.NEAREST)!;
        const px = grid.get_pixels(), n = grid.get_n_channels();
        let sum = 0;
        for (let y = 0; y < 9; y++) for (let x = 0; x < 16; x++) {
          const i = y * grid.rowstride + x * n;
          sum += 0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2];
        }
        setWallpaperLight(sum / 144 > 150);
      } catch { }
    });
  } catch { }
};

export default () =>
  <For each={monitors}>
    {(monitor) => <This this={app}>
      <window
        name="wallpaper"
        namespace="wallpaper"
        anchor={TOP | BOTTOM | LEFT | RIGHT}
        exclusivity={Astal.Exclusivity.IGNORE}
        layer={Astal.Layer.BACKGROUND}
        gdkmonitor={monitor}
        application={app}
        visible
        $={(self) => onCleanup(() => self.destroy())}
      >
        <Gtk.Picture paintable={wallpaperTexture} contentFit={Gtk.ContentFit.COVER} />
      </window>
    </This>}
  </For>;
