import { Gtk } from 'ags/gtk4';
import GLib from 'gi://GLib';
import { currentAsideWindow } from '../../lib/asideState';

export default () =>
    <Gtk.Calendar $={(self) => currentAsideWindow.subscribe(() => {
        if (currentAsideWindow.peek() !== 'calendar') return;
        self.set_date(GLib.DateTime.new_now_local());
        self.get_first_child()?.get_first_child()?.grab_focus();
    })}/>
