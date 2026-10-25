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
const [ loaded, setLoaded ] = createState(false);

const listFiles = (dir: string): string[] => listDir(dir).flatMap((i) => {
  const path = `${dir}/${i.get_name()}`;
  return i.get_file_type() == Gio.FileType.DIRECTORY ? listFiles(path) : [path];
});

type Wallpaper = { path: string, texture: Gdk.Texture, light: boolean };

const decode = (path: string, p: GdkPixbuf.Pixbuf): Wallpaper => {
  const format = p.hasAlpha ? Gdk.MemoryFormat.R8G8B8A8 : Gdk.MemoryFormat.R8G8B8;
  const texture = Gdk.MemoryTexture.new(p.width, p.height, format, p.read_pixel_bytes(), p.rowstride);
  const grid = p.scale_simple(16, 9, GdkPixbuf.InterpType.NEAREST)!;
  const px = grid.get_pixels(), n = grid.get_n_channels();
  let sum = 0;
  for (let y = 0; y < 9; y++) for (let x = 0; x < 16; x++) {
    const i = y * grid.rowstride + x * n;
    sum += 0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2];
  }
  return { path, texture, light: sum / 144 > 150 };
};

let current = '';

const pick = () => {
  const files = listFiles('/home/alec/Wallpapers').filter((f) => f != current);
  return files.length ? files[Math.floor(Math.random() * files.length)] : null;
};

const load = (path: string | null) => new Promise<Wallpaper | null>((resolve) => {
  if (!path) return resolve(null);
  try {
    GdkPixbuf.Pixbuf.new_from_stream_async(Gio.File.new_for_path(path).read(null), null, (_, res) => {
      try {
        resolve(decode(path, GdkPixbuf.Pixbuf.new_from_stream_finish(res)));
      } catch {
        resolve(null);
      }
    });
  } catch {
    resolve(null);
  }
});

let next = load(pick());
let queue = Promise.resolve();

export const randomWallpaper = () => queue = queue.then(async () => {
  const w = await next ?? await load(pick());
  if (w) {
    current = w.path;
    setWallpaperTexture(w.texture);
    setWallpaperLight(w.light);
    setLoaded(true);
  }
  next = load(pick());
}).catch(() => { });

export default () => perMonitor((monitor) =>
  <window
    name="wallpaper"
    namespace="wallpaper"
    anchor={TOP | BOTTOM | LEFT | RIGHT}
    exclusivity={Astal.Exclusivity.IGNORE}
    layer={Astal.Layer.BACKGROUND}
    gdkmonitor={monitor}
    application={app}
    visible={loaded}
    onRealize={(self) => self.get_surface()?.set_input_region(new cairo.Region())}
  >
    <Gtk.Picture paintable={wallpaperTexture} contentFit={Gtk.ContentFit.COVER} />
  </window>);
