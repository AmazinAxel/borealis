import Apps from 'gi://AstalApps';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { createState, For } from 'ags';
import { execAsync } from 'ags/process';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';
import { focus } from '../focus';

const apps = new Apps.Apps();
let textBox: Gtk.Entry;
const [ appsList, setAppsList ] = createState<Apps.Application[]>([]);

const focusBlockedAppNames = ['discord', 'slack'];

const blockable = (a: Apps.Application) =>
  focusBlockedAppNames.some((b) => a.name.toLowerCase().includes(b));
const isBlocked = (a: Apps.Application) => focus.peek() && blockable(a);

const search = (text: string) => setAppsList(
  !text ? [] : apps.fuzzy_query(text).slice(0, 5)
);

const launchApp = (selectedApp?: Apps.Application) => {
  if (!selectedApp || isBlocked(selectedApp)) return;
  const cmd = selectedApp.executable.replace(/ ?%[a-zA-Z]/g, '').trim();
  app.toggle_window('launcher');
  execAsync(['swaymsg', 'exec', '--', cmd]);
};

export default () => inputControl('launcher', () =>
  <BackgroundSection
    height={700} width={500}
    header={<entry
      $type="overlay"
      primaryIconName="system-search-symbolic"
      placeholderText="Search"
      onActivate={() => launchApp(appsList.peek()[0])}
      onNotifyText={({ text }) => search(text)}
      $={(self) => textBox = self} />}
    content={<box spacing={6} orientation={Gtk.Orientation.VERTICAL} visible={appsList((l) => l.length > 0)}>
      <For each={appsList}>
        {(entry) => {
          const blocked = focus((f) => f && blockable(entry));
          return <button
            canTarget={false}
            onClicked={() => launchApp(entry)}
            sensitive={blocked((b) => !b)}
            cssClasses={blocked((b) => b ? ['button', 'blocked'] : ['button'])}
          >
            <box>
              <image iconName={entry.iconName} />
              <label cssClasses={['name']} xalign={0} valign={Gtk.Align.CENTER} label={entry.name} />
            </box>
          </button>;
        }}
      </For>
    </box>}
  />,
  { onShow: () => textBox.text = '', searchable: true, focus: () => textBox });
