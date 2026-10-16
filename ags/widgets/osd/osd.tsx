import { createState, createBinding, For, This, onCleanup } from 'ags';
import { timeout } from 'ags/time';
import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Wp from 'gi://AstalWp';
import { brightness } from '../../lib/brightness';
import { monitors } from '../../lib/monitors';
import OutTransition, { createFlash } from '../../lib/outTransition';

const audio = Wp.get_default()!.audio;
let dontShow = true;
const [ icon, setIcon ] = createState('');
const [ val, setVal ] = createState(0);
const { visible, reveal, show, onHidden } = createFlash(500);

timeout(2000, () => dontShow = false); // stop osd from showing when ags starts

const osdChange = (iconType: string, value: number) => {
    if (dontShow) return;
    setIcon(iconType);
    setVal(value);
    show();
};

brightness.subscribe(() => osdChange('display-brightness-symbolic', brightness.peek()));
const volumeChanged = () => audio.defaultSpeaker && osdChange(audio.defaultSpeaker.volumeIcon, audio.defaultSpeaker.volume);
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
                defaultHeight={1} // fix bug
                defaultWidth={1}
                $={(self) => onCleanup(() => self.destroy())}
            >
                <OutTransition duration={125} reveal={reveal} onHidden={onHidden} type={Gtk.RevealerTransitionType.SLIDE_UP}>
                    <box cssClasses={['osd']}>
                        <image iconName={icon}/>
                        <levelbar value={val} widthRequest={400}/>
                    </box>
                </OutTransition>
            </window>
        </This>}
    </For>
