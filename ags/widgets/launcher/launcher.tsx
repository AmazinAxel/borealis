import Apps from 'gi://AstalApps';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { swayCommand } from '../../lib/sway';
import searchDialog from '../../lib/searchDialog';
import { focus } from '../focus';

const apps = new Apps.Apps();

const focusBlockedAppNames = ['discord', 'slack'];

const blockable = (a: Apps.Application) =>
  focusBlockedAppNames.some((b) => a.name.toLowerCase().includes(b));

const launchApp = (selectedApp: Apps.Application) => {
  if (focus.peek() && blockable(selectedApp)) return;
  const cmd = selectedApp.executable.replace(/ ?%[a-zA-Z]/g, '').trim();
  app.toggle_window('launcher');
  swayCommand(`exec ${cmd}`);
};

export default () => searchDialog('launcher', {
  placeholder: 'Search',
  search: (text) => !text ? [] : apps.fuzzy_query(text).slice(0, 5),
  activate: launchApp,
  sensitive: (entry) => focus((f) => !(f && blockable(entry))),
  row: (entry) =>
    <box>
      <image iconName={entry.iconName} />
      <label cssClasses={['name']} xalign={0} valign={Gtk.Align.CENTER} label={entry.name} />
    </box>,
});
