import { subprocess } from 'ags/process';
import { createState } from 'ags';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';

const readNum = (path: string) => {
  try {
    const [ ok, contents ] = GLib.file_get_contents(path);
    return ok ? Number(new TextDecoder().decode(contents).trim()) : 0;
  } catch { return 0; }
};

const backlightDir = '/sys/class/backlight';
const listScreens = () => {
  const names: string[] = [];
  try {
    const e = Gio.File.new_for_path(backlightDir)
      .enumerate_children('standard::name', Gio.FileQueryInfoFlags.NONE, null);
    for (let i = e.next_file(null); i; i = e.next_file(null)) names.push(i.get_name());
  } catch { }
  return names.sort();
};

const screen = listScreens()[0] ?? '';
const brightnessPath = `${backlightDir}/${screen}/brightness`;

const screenMax = readNum(`${backlightDir}/${screen}/max_brightness`);
export const [ brightness, setBrightnessValue ] = createState(readNum(brightnessPath) / (screenMax || 1));

export const setBrightness = (percent: number) => {
  if (!screenMax) return;
  const steps = Math.max(0, Math.min(screenMax, Math.floor(percent * screenMax)));
  setBrightnessValue(steps / screenMax);
  Gio.DBus.system.call('org.freedesktop.login1', '/org/freedesktop/login1/session/auto', 'org.freedesktop.login1.Session',
    'SetBrightness', new GLib.Variant('(ssu)', ['backlight', screen, steps]), null, Gio.DBusCallFlags.NONE, -1, null, null);
};

export const monitorBrightness = () =>
  !screen ? null : subprocess(
    ['udevadm', 'monitor', '--udev', '--subsystem-match=backlight'],
    (line) => {
      if (!line.includes(screen)) return;
      const v = readNum(brightnessPath) / screenMax;
      if (v !== brightness.peek()) setBrightnessValue(v); // only updates for non internal changes
    }
  );

export const BrightnessSlider = () =>
  <box visible={!!screen}>
    <image iconName="display-brightness-symbolic" />
    <slider
      hexpand
      focusable={false}
      value={brightness}
      onChangeValue={({ value }) => setBrightness(value)}
    />
  </box>
