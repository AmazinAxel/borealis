import { createState, createBinding, For, This, onCleanup } from 'ags';
import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Wp from 'gi://AstalWp';
import { brightness } from '../../lib/brightness';
import { monitors } from '../../lib/monitors';
import OutTransition, { createFlash } from '../../lib/outTransition';

const audio = Wp.get_default()!.audio;
const [ icon, setIcon ] = createState('');
const [ val, setVal ] = createState(0);
const { visible, reveal, show, onHidden } = createFlash(500);

const osdChange = (iconType: string, value: number) => {
  setIcon(iconType);
  setVal(value);
  show();
};

brightness.subscribe(() => osdChange('display-brightness-symbolic', brightness.peek()));
let speaker = audio.defaultSpeaker;
const volumeChanged = () => {
  const s = audio.defaultSpeaker;
  if (s && s == speaker) osdChange(s.volumeIcon, s.volume);
  speaker = s;
};
createBinding(audio, 'defaultSpeaker', 'volume').subscribe(volumeChanged);
createBinding(audio, 'defaultSpeaker', 'mute').subscribe(volumeChanged);

export default () =>
  <For each={monitors}>
    {(monitor) => <This this={app}>
      <window
        name="osd"
        anchor={Astal.WindowAnchor.BOTTOM}
        application={app}
        layer={Astal.Layer.OVERLAY}
        gdkmonitor={monitor}
        visible={visible}
        resizable={false}
        $={(self) => onCleanup(() => self.destroy())}
      >
        <OutTransition duration={125} reveal={reveal} onHidden={onHidden} type={Gtk.RevealerTransitionType.SLIDE_UP}>
          <box cssClasses={['osd']}>
            <image iconName={icon} />
            <levelbar value={val} widthRequest={400} />
          </box>
        </OutTransition>
      </window>
    </This>}
  </For>;
