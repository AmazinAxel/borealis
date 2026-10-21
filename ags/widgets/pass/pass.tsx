import GLib from 'gi://GLib';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { execAsync } from 'ags/process';
import searchDialog from '../../lib/searchDialog';
import { copyLogin } from '../../lib/clipboard';

const STORE = `${GLib.get_home_dir()}/.password-store`;

let entries: string[] = [];

const loadEntries = async () => {
  const out = await execAsync(['find', STORE, '-type', 'f', '-name', '*.gpg']).catch(() => '');
  entries = out.split('\n').filter(Boolean).map((f) => f.slice(STORE.length + 1, -4)).sort();
};

const search = (q: string) => {
  if (q.length < 2) return [];
  const ql = q.toLowerCase();
  return entries
    .map((n) => [n, n.toLowerCase().indexOf(ql)] as const)
    .filter(([ , s ]) => s >= 0)
    .sort((a, b) => a[1] - b[1])
    .slice(0, 5)
    .map(([ n ]) => n);
};

const copyPair = async (name: string) => {
  app.get_window('pass')?.set_visible(false);
  const [ password, login = '' ] = (await execAsync(['pass', 'show', name]).catch(() => '')).split('\n');
  if (!password) return;
  const user = login.replace(/^\s*(login|username|user|email):\s*/i, '').trim() || name.split('/').pop()!;
  copyLogin(user, password);
};

loadEntries();

export default () => searchDialog('pass', {
  placeholder: 'Passwords',
  search,
  activate: copyPair,
  row: (name) => <label cssClasses={['name']} xalign={0} valign={Gtk.Align.CENTER} label={name} />,
  onShow: loadEntries,
});
