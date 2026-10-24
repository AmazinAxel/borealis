import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import app from 'ags/gtk4/app';
import BackgroundSection from '../../lib/backgroundSection';
import { recMic, setRecMic, recQuality, startRec, setRecQuality, isRec, saveClip } from './service';
import inputControl from '../../lib/inputControl';

const handleKeys = (_ctrl: Gtk.EventControllerKey, key: number) => {
  switch (Gdk.keyval_to_lower(key)) {
    case Gdk.KEY_space: // start recording
      startRec();
      app.get_window('recordMenu')?.set_visible(false);
      break;
    case Gdk.KEY_c: // clip & save last 30 seconds
      saveClip();
      app.get_window('recordMenu')?.set_visible(false);
      break;
    case Gdk.KEY_r: // toggle microphone input
      setRecMic(!recMic.peek());
      break;
    case Gdk.KEY_q: // toggle quality
      setRecQuality(recQuality.peek() == 'Medium' ? 'Ultra' : 'Medium');
      break;
  }
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
  { onKeyPressed: handleKeys }
);

export const RecordingIndicator = () =>
  <image
    visible={isRec}
    halign={Gtk.Align.CENTER}
    cssClasses={['recIndicator']}
    iconName="media-record-symbolic" />
