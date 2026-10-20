import { Gtk } from 'ags/gtk4';
import { wallpaperTexture, wallpaperLight } from './wallpaper';

export default ({ header, content, height, width }: { header: JSX.Element, content?: JSX.Element, height?: number, width: number }) =>
  <box
    heightRequest={height}
    halign={Gtk.Align.CENTER}
    valign={Gtk.Align.CENTER}
  >
    <box
      widthRequest={width}
      spacing={5}
      cssClasses={['widgetBackground', 'backgroundSection']}
      orientation={Gtk.Orientation.VERTICAL}
      valign={Gtk.Align.START}
    >
      <overlay cssClasses={wallpaperLight((l) => l ? ['header', 'light'] : ['header'])}>
        <box cssClasses={['backgroundOverlay']} />
        <Gtk.Picture paintable={wallpaperTexture} contentFit={Gtk.ContentFit.COVER} cssClasses={['backgroundImage']} $type="overlay" />
        {header}
      </overlay>

      {content}
    </box>
  </box>;
