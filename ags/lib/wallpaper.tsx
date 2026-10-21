import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Gdk from 'gi://Gdk';
import GdkPixbuf from 'gi://GdkPixbuf';
import Gio from 'gi://Gio';
import cairo from 'cairo';
import { createState } from 'ags';
import perMonitor from './perMonitor';
import listDir from './listDir';

const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

export const [ wallpaperTexture, setWallpaperTexture ] = createState<Gdk.Paintable>(Gdk.Paintable.new_empty(1, 1));
export const [ wallpaperLight, setWallpaperLight ] = createState(false);

const listFiles = (dir: string): string[] => listDir(dir).flatMap((i) => {
  const path = `${dir}/${i.get_name()}`;
  return i.get_file_type() == Gio.FileType.DIRECTORY ? listFiles(path) : [path];
});

let current = '';
export const randomWallpaper = () => {
  const files = listFiles('/home/alec/Wallpapers').filter((f) => f != current);
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

export default () => perMonitor((monitor) =>
  <window
    name="wallpaper"
    namespace="wallpaper"
    anchor={TOP | BOTTOM | LEFT | RIGHT}
    exclusivity={Astal.Exclusivity.IGNORE}
    layer={Astal.Layer.BACKGROUND}
    gdkmonitor={monitor}
    application={app}
    visible
    $={(self) => self.get_surface()?.set_input_region(new cairo.Region())}
  >
    <Gtk.Picture paintable={wallpaperTexture} contentFit={Gtk.ContentFit.COVER} />
  </window>);
