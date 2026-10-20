import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

export const pipe = (argv: string[], input: string) => new Promise<boolean>((resolve) => {
  try {
    const p = Gio.Subprocess.new(argv, Gio.SubprocessFlags.STDIN_PIPE);
    p.communicate_utf8_async(input, null, () => resolve(p.get_successful()));
  } catch {
    resolve(false);
  }
});

export const copy = (text: string, type = 'text/plain') => pipe(['wl-copy', '-n', '-t', type], text);

export const copyUri = (path: string) => copy(GLib.filename_to_uri(path, null) + '\r\n', 'text/uri-list');

export const copyLogin = async (user: string, password: string) => {
  await pipe(['cliphist', 'store'], user);
  copy(password);
};
