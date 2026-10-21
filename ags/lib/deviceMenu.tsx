import { Gtk } from 'ags/gtk4';
import { type Accessor } from 'ags';

export default ({ powered, powerIcon, scanning, scanSensitive, onPower, onScan, power, scan, list, children }: {
  powered: Accessor<boolean>,
  powerIcon: string | Accessor<string>,
  scanning: Accessor<boolean>,
  scanSensitive?: Accessor<boolean>,
  onPower: () => void,
  onScan: () => void,
  power?: (self: Gtk.Button) => void,
  scan?: (self: Gtk.Button) => void,
  list: (self: Gtk.Box) => void,
  children: JSX.Element,
}) =>
  <box orientation={Gtk.Orientation.VERTICAL}>
    <box>
      <button
        canTarget={false}
        hexpand halign={Gtk.Align.START}
        onClicked={onPower}
        cssClasses={powered((on) => [on ? 'active' : 'unpowered'])}
        $={power}
      >
        <image iconName={powerIcon} />
      </button>
      <button
        canTarget={false}
        onClicked={onScan}
        sensitive={scanSensitive ?? true}
        visible={powered}
        cssClasses={scanning((s) => s ? ['active'] : [])}
        $={scan}
      >
        <image iconName="view-refresh-symbolic" />
      </button>
    </box>
    <Gtk.Separator visible={powered} />
    <scrolledwindow
      hscrollbarPolicy={Gtk.PolicyType.NEVER}
      hexpand vexpand
      propagateNaturalWidth propagateNaturalHeight
      maxContentHeight={500}
      visible={powered}
    >
      <box orientation={Gtk.Orientation.VERTICAL} $={list}>
        {children}
      </box>
    </scrolledwindow>
  </box>;
