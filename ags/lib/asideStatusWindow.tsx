import { currentAsideWindow, closeAsideWindow } from "./asideState"
import { Astal, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Gdk from "gi://Gdk"
import wrapFocus from "./wrapFocus"
import bluetooth from "./bluetooth"
import { statusMargin } from "../widgets/status/status"
import quickSettings from "../widgets/status/quicksettings/quicksettings"
import wifi from "../widgets/status/network"
import calendar from "../widgets/status/calendar"
const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

const menus = { quickSettings, bluetooth, wifi, calendar };

export default () =>
    <window
        name="asideStatus"
        namespace="asideStatus"
        keymode={Astal.Keymode.EXCLUSIVE}
        anchor={TOP | BOTTOM | LEFT | RIGHT}
        application={app}
        layer={Astal.Layer.OVERLAY}
        visible={currentAsideWindow((a) => a !== null)}
        class="backgroundDim"
    >
        <Gtk.EventControllerKey onKeyPressed={(_, key) => key == Gdk.KEY_Escape && closeAsideWindow()}/>
        <Gtk.EventControllerKey propagationPhase={Gtk.PropagationPhase.CAPTURE} onKeyPressed={wrapFocus}/>
        <box
            halign={Gtk.Align.START}
            valign={Gtk.Align.END}
            marginStart={statusMargin}
            cssClasses={['asideStatusWidget']}
        >
            {Object.entries(menus).map(([name, Content]) =>
                <box visible={currentAsideWindow((a) => a === name)}>
                    <Content/>
                </box>
            )}
        </box>
    </window>
