import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import app from 'ags/gtk4/app';
import BackgroundSection from '../../lib/backgroundSection';
import { recMic, setRecMic, recQuality, startRec, setRecQuality, isRec, saveClip } from './service';
import inputControl, { type Actions } from '../../lib/inputControl';

const hide = () => app.get_window('recordMenu')?.set_visible(false);

const actions: Actions = {
  [Gdk.KEY_space]: () => { startRec(); hide(); }, // start recording
  [Gdk.KEY_c]: () => { saveClip(); hide(); }, // clip & save last 30 seconds
  [Gdk.KEY_r]: () => setRecMic(!recMic.peek()), // toggle microphone input
  [Gdk.KEY_q]: () => setRecQuality(recQuality.peek() == 'Medium' ? 'Ultra' : 'Medium'), // toggle quality
};

export default () => inputControl('recordMenu', () =>
  <BackgroundSection
    height={100} width={350}
    header={
      <box $type="overlay" hexpand vexpand halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} spacing={8}>
        <image iconSize={Gtk.IconSize.LARGE} iconName={recMic((m) => m ? 'audio-input-microphone-symbolic' : 'microphone-disabled-symbolic')} />
        <label label={recQuality} />
      </box>
    }
  />,
  { actions }
);

export const RecordingIndicator = () =>
  <image
    visible={isRec}
    halign={Gtk.Align.CENTER}
    cssClasses={['recIndicator']}
    iconName="media-record-symbolic" />
