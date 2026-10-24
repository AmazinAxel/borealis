import { createState, createBinding } from 'ags';
import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { audio, wp } from '../../lib/audio';
import { brightness } from '../../lib/brightness';
import perMonitor from '../../lib/perMonitor';
import OutTransition, { createFlash } from '../../lib/outTransition';

const [ icon, setIcon ] = createState('');
const [ val, setVal ] = createState(0);
const { visible, reveal, show, onHidden } = createFlash(500);

const osdChange = (iconType: string, value: number) => {
  setIcon(iconType);
  setVal(value);
  show();
};

brightness.subscribe(() => osdChange('display-brightness-symbolic', brightness.peek()));
let ready = false;
let speaker = audio.defaultSpeaker;
wp.connect('ready', () => {
  ready = true;
  speaker = audio.defaultSpeaker;
});
const volumeChanged = () => {
  if (!ready) return;
  const s = audio.defaultSpeaker;
  if (s && s == speaker) osdChange(s.volumeIcon, s.volume);
  speaker = s;
};
createBinding(audio, 'defaultSpeaker', 'volume').subscribe(volumeChanged);
createBinding(audio, 'defaultSpeaker', 'mute').subscribe(volumeChanged);

export default () => perMonitor((monitor) =>
  <window
    name="osd"
    anchor={Astal.WindowAnchor.BOTTOM}
    application={app}
    layer={Astal.Layer.OVERLAY}
    gdkmonitor={monitor}
    visible={visible}
    resizable={false}
  >
    <OutTransition duration={125} reveal={reveal} onHidden={onHidden} type={Gtk.RevealerTransitionType.SLIDE_UP}>
      <box cssClasses={['statusElement', 'osd']}>
        <image iconName={icon} />
        <levelbar value={val} widthRequest={400} />
      </box>
    </OutTransition>
  </window>);
