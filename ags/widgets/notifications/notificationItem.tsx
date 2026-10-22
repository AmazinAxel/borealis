import GLib from 'gi://GLib';
import { Gtk } from 'ags/gtk4';
import Notifd from 'gi://AstalNotifd';
import Pango from 'gi://Pango';
import { swayCommand } from '../../lib/sway';
const { START, CENTER, END } = Gtk.Align;

const time = (t: number) => GLib.DateTime.new_from_unix_local(t).format('%H:%M')!;

const capitalizeFirstLetter = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

const invoke = (n: Notifd.Notification, id: string) => {
  n.invoke(id);
  const app = n.desktopEntry || n.appName;
  if (id === 'default' && app) swayCommand(`[app_id="${app}"] focus`);
  if (!n.resident) n.dismiss();
};

export const invokeAction = (n: Notifd.Notification, i = 0) => {
  const action = n.get_actions()[i];
  if (action) invoke(n, action.id);
};

export const notificationItem = (n: Notifd.Notification) =>
  <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['statusElement', 'notification']}>
    <box cssClasses={['header']}>
      <label
        cssClasses={['appName']}
        halign={START}
        ellipsize={Pango.EllipsizeMode.END}
        label={capitalizeFirstLetter(n.appName ?? 'Unknown')}
      />
      <label hexpand halign={END} label={time(n.time)} />
    </box>
    <box cssClasses={['content']}>
      <box orientation={Gtk.Orientation.VERTICAL}>
        {n.summary?.trim() && <label
          cssClasses={['summary']}
          halign={START}
          wrap
          xalign={0}
          label={n.summary}
          maxWidthChars={30}
        />}
        {n.body?.trim() && <label
          wrap
          xalign={0}
          label={n.body}
          maxWidthChars={30}
        />}
        {n.get_actions().length > 0 && <box cssClasses={['actions']} spacing={5}>
          {n.get_actions().map(({ label }) =>
            <button hexpand canTarget={false} focusable={false}>
              <label label={label.replace('Activate', 'Open')} halign={CENTER} />
            </button>
          )}
        </box>}
      </box>
    </box>
  </box>;
