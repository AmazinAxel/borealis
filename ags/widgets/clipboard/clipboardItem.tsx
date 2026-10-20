import { execAsync } from 'ags/process';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import GdkPixbuf from 'gi://GdkPixbuf';
import Gdk from 'gi://Gdk';
import { Gtk } from 'ags/gtk4';
import { streamingMode } from '../../lib/streamingMode';

export const cacheDir = '/tmp/ags/cliphist';
GLib.mkdir_with_parents(cacheDir, 0o755);
export const videoExts = /\.(mp4|mkv|webm|mov|m4v|avi)$/i;

const maxWidth = 400, maxHeight = 150;
let produceQueue: Promise<unknown> = Promise.resolve();
export const binaryData = /\[\[ binary data \d+ (?:B|KiB|MiB|GiB) (\w+) (\d+)x(\d+) \]\]/;

export const entryPath = (id: string, content: string) => {
  const binary = content.match(binaryData);
  if (binary) return `${cacheDir}/${id}.${binary[1]}`;

  const single = content.trim();
  if (single.includes('\n') || single.includes(' ')) return null; // not a path

  const path = single.startsWith('file:')
    ? decodeURIComponent(single.replace(/^file:\/*/, '/'))
    : single;

  return path.startsWith('/') ? path : null;
};

const Thumbnail = (id: string, file: string, produce: string[], video = false) => {
  const picture = new Gtk.Picture({ contentFit: Gtk.ContentFit.CONTAIN });

  const container = <box cssClasses={['image']} name={id} overflow={Gtk.Overflow.HIDDEN}
    valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER}>
    <overlay>
      {picture}
      {video && <image $type="overlay" cssClasses={['playIcon']} pixelSize={42}
        iconName="media-playback-start-symbolic"
        halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} />}
    </overlay>
  </box> as Gtk.Box;

  const load = () => {
    try {
      const stream = Gio.File.new_for_path(file).read(null);
      GdkPixbuf.Pixbuf.new_from_stream_at_scale_async(stream, maxWidth, maxHeight, true, null, (_, res) => {
        try {
          const pixbuf = GdkPixbuf.Pixbuf.new_from_stream_finish(res);
          picture.set_paintable(Gdk.Texture.new_for_pixbuf(pixbuf));
          container.set_size_request(pixbuf.get_width(), pixbuf.get_height());
        } catch { } finally {
          stream.close_async(0, null, null);
        }
      });
    } catch { }
  };

  if (GLib.file_test(file, GLib.FileTest.EXISTS))
    load();
  else
    produceQueue = produceQueue.then(() => execAsync(produce)).then(load).catch(() => { }); // producer can fail on odd media

  return container;
};

export const ClipboardItem = (id: string, content: string, path: string | null, image: RegExpMatchArray | null) => {
  const video = path !== null && videoExts.test(path) && GLib.file_test(path, GLib.FileTest.EXISTS);

  if (streamingMode.peek()) // describe
    return <label xalign={0} name={id} label={
      image ? `Image (${image[2]}x${image[3]})`
        : video ? `Video (${path.split('/').pop()})`
          : `Text (${content.length} chars)`
    } />;

  if (image)
    return Thumbnail(id, path!, ['bash', '-c', `cliphist decode ${id} > ${path}`]);

  if (video) {
    const thumb = `${cacheDir}/${id}.jpg`;
    return Thumbnail(id, thumb, ['ffmpeg', '-v', 'error', '-i', path, '-vf',
      `thumbnail,scale=w=${maxWidth}:h=${maxHeight}:force_original_aspect_ratio=decrease`,
      '-frames:v', '1', '-y', thumb], true);
  }

  return <label label={content} xalign={0} wrap name={id} />;
};
