import Gio from 'gi://Gio';

export default (dir: string) => {
  const infos: Gio.FileInfo[] = [];
  try {
    const e = Gio.File.new_for_path(dir).enumerate_children('standard::name,standard::type', Gio.FileQueryInfoFlags.NONE, null);
    for (let i = e.next_file(null); i; i = e.next_file(null)) infos.push(i);
  } catch { }
  return infos;
};
