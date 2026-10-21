import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Notifd from 'gi://AstalNotifd';
import { notificationItem, invokeAction } from './notificationItem';
import { createState, For } from 'ags';
import perMonitor from '../../lib/perMonitor';
import { focus } from '../focus';

const { TOP, RIGHT } = Astal.WindowAnchor;
import { streamingMode } from '../../lib/streamingMode';

const notifd = Notifd.get_default();
const map = new Map<number, Notifd.Notification>();
export const [ notificationlist, setNotificationList ] = createState<Notifd.Notification[]>([])

const notify = () => setNotificationList([...map.values()].reverse());

const hidden = (n: Notifd.Notification) =>
  ((streamingMode.peek() || focus.peek()) && n.appName != 'Low battery')
  || n.body.startsWith('Failed to connect to server'); // Hide annoying message

notifd.connect('notified', (_, id) => {
  const n = notifd.get_notification(id);
  if (!n) return;
  if (hidden(n)) return n.dismiss();
  map.set(id, n);
  notify();
});
notifd.connect('resolved', (_, id) => map.delete(id) && notify());

export const notifications = () => perMonitor((monitor) =>
  <window
    name="notifications"
    anchor={TOP | RIGHT}
    application={app}
    layer={Astal.Layer.TOP}
    gdkmonitor={monitor}
    resizable={false}
    visible={notificationlist((n) => n.length != 0)}
  >
    <box orientation={Gtk.Orientation.VERTICAL} widthRequest={200}>
      <For each={notificationlist}>
        {notificationItem}
      </For>
    </box>
  </window>);

export const clearOldestNotification = () =>
  map.values().next().value?.dismiss();

export const invokeOldestNotification = (i = 0) => {
  const oldest = map.values().next().value;
  if (oldest) invokeAction(oldest, i);
};
