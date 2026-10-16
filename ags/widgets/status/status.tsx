import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createState } from 'ags';
import { Time } from './modules/time';
import { Status } from './modules/statusIcons';
import { Mpris } from './modules/mpris';
import { Media } from '../../lib/mediaPlayer';
import { RecordingIndicator } from '../record/record';
import Wp from "gi://AstalWp";

const { BOTTOM, LEFT } = Astal.WindowAnchor;
const audio = Wp.get_default()!.audio;

export const [ statusMargin, setStatusMargin ] = createState(0);

export default () =>
  <window
    name="status"
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    anchor={BOTTOM | LEFT}
    layer={Astal.Layer.OVERLAY}
    application={app}
  >
    <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.END}>
      <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} cssClasses={['statusElement']} name={'media'}>
        <Media/>
        <Mpris/>
      </box>

      <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['statusElement', 'infoCenter']}>
        <Gtk.EventControllerScroll
          flags={Gtk.EventControllerScrollFlags.VERTICAL}
          onScroll={(self, __, y) => {
            const speaker = audio.defaultSpeaker;
            if (speaker) speaker.volume -= self.get_unit() === Gdk.ScrollUnit.WHEEL ? Math.sign(y) * 0.05 : y * 0.002;
          }}
        />
        <RecordingIndicator/>
        <Time/>
        <Status/>
      </box>
    </box>
  </window>
