import Apps from 'gi://AstalApps';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { swayCommand } from '../../lib/sway';
import searchDialog from '../../lib/searchDialog';
import { focus, startBreak } from '../focus';

const apps = new Apps.Apps();

const focusBlockedAppNames = ['discord'];

const blockable = (a: Apps.Application) =>
  focusBlockedAppNames.some((b) => a.name.toLowerCase().includes(b));

const appCmd = (a: Apps.Application) => a.executable.replace(/ ?%[a-zA-Z]/g, '').trim();

const launchApp = (selectedApp: Apps.Application) => {
  if (focus.peek() && blockable(selectedApp)) return;
  app.toggle_window('launcher');
  swayCommand(`exec ${appCmd(selectedApp)}`);
};

const breakLaunch = (selectedApp: Apps.Application) => {
  if (!focus.peek() || !blockable(selectedApp)) return launchApp(selectedApp);
  app.toggle_window('launcher');
  startBreak(appCmd(selectedApp));
};

export default () => searchDialog('launcher', {
  placeholder: 'Search',
  search: (text) => !text ? [] : apps.fuzzy_query(text).slice(0, 5),
  activate: launchApp,
  shiftActivate: breakLaunch,
  sensitive: (entry) => focus((f) => !(f && blockable(entry))),
  row: (entry) =>
    <box>
      <image iconName={entry.iconName} />
      <label cssClasses={['name']} xalign={0} valign={Gtk.Align.CENTER} label={entry.name} />
    </box>,
});
