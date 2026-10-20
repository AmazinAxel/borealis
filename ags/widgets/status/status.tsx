import app from 'ags/gtk4/app';
import { Astal, Gdk, Gtk } from 'ags/gtk4';
import { createState } from 'ags';
import Wp from 'gi://AstalWp';
import { Time } from './modules/time';
import { Status } from './modules/statusIcons';
import { Mpris } from './modules/mpris';
import { Media, playlistClass } from '../../lib/mediaPlayer';
import { RecordingIndicator } from '../record/record';

const { BOTTOM, LEFT } = Astal.WindowAnchor;
const audio = Wp.get_default()!.audio;

export const [ statusMargin, setStatusMargin ] = createState(0);

export default () =>
  <window
    name="status"
    anchor={BOTTOM | LEFT}
    layer={Astal.Layer.OVERLAY}
    application={app}
  >
    <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.END}>
      <box
        orientation={Gtk.Orientation.VERTICAL}
        halign={Gtk.Align.CENTER}
        name="media"
        cssClasses={playlistClass((p) => ['statusElement', p])}
      >
        <Media />
        <Mpris />
      </box>

      <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['statusElement', 'infoCenter']}>
        <Gtk.EventControllerScroll
          flags={Gtk.EventControllerScrollFlags.VERTICAL}
          onScroll={(self, _dx, dy) => {
            const speaker = audio.defaultSpeaker;
            if (speaker) speaker.volume -= self.get_unit() == Gdk.ScrollUnit.WHEEL ? Math.sign(dy) * 0.05 : dy * 0.002;
          }}
        />
        <RecordingIndicator />
        <Time />
        <Status />
      </box>
    </box>
  </window>;
