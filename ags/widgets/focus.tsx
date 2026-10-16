import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { createState, For, This, onCleanup } from 'ags';
import { monitors } from '../lib/monitors';
import BackgroundSection from '../lib/backgroundSection';
import inputControl from '../lib/inputControl';

const { TOP } = Astal.WindowAnchor;
let textBox: Gtk.Entry;

export const [ focusText, setFocusText ] = createState('');
export const focus = focusText(Boolean);

export const toggleFocus = () =>
    focus.peek() ? setFocusText('') : app.toggle_window('focusMenu');

const startFocus = () => {
    const text = textBox.text.trim();
    if (!text) return;
    setFocusText(text);
    app.get_window('focusMenu')?.hide();
};

export const focusMenu = () => inputControl('focusMenu', () =>
    <BackgroundSection
        width={400}
        header={<entry
            $type="overlay"
            primaryIconName="emoji-flags-symbolic"
            placeholderText="Task"
            maxLength={60}
            onActivate={startFocus}
            $={self => { textBox = self; }}/>}/>,
    { onShow: () => textBox.text = '', searchable: true, focus: () => textBox });

export const focusTask = () =>
    <For each={monitors}>
        {(monitor) => <This this={app}>
            <window
                name="focusTask"
                namespace="focusTask"
                anchor={TOP} // fullscreen cant cover this!!
                layer={Astal.Layer.TOP}
                gdkmonitor={monitor}
                application={app}
                visible={focus}
                $={(self) => onCleanup(() => self.destroy())}
            >
                <label cssClasses={['statusElement']} label={focusText}/>
            </window>
        </This>}
    </For>;
