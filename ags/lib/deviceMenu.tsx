import { Gtk } from 'ags/gtk4';
import { type Accessor } from 'ags';
import { setUpExit } from './wrapFocus';

export default ({ powered, powerIcon, scanning, scanSensitive, upTo, onPower, onScan, power, scan, list, children }: {
  powered: Accessor<boolean>,
  powerIcon: string | Accessor<string>,
  scanning: Accessor<boolean>,
  scanSensitive?: Accessor<boolean>,
  upTo: 'power' | 'scan',
  onPower: () => void,
  onScan: () => void,
  power?: (self: Gtk.Button) => void,
  scan?: (self: Gtk.Button) => void,
  list?: (self: Gtk.Box) => void,
  children: JSX.Element,
}) => {
  let powerButton: Gtk.Button, scanButton: Gtk.Button;
  return <box orientation={Gtk.Orientation.VERTICAL}>
    <box>
      <button
        canTarget={false}
        hexpand halign={Gtk.Align.START}
        onClicked={onPower}
        cssClasses={powered((on) => [on ? 'active' : 'unpowered'])}
        $={(self) => {
          powerButton = self;
          power?.(self);
        }}
      >
        <image iconName={powerIcon} />
      </button>
      <button
        canTarget={false}
        onClicked={onScan}
        sensitive={scanSensitive ?? true}
        visible={powered}
        cssClasses={scanning((s) => s ? ['active'] : [])}
        $={(self) => {
          scanButton = self;
          scan?.(self);
        }}
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
      <box
        orientation={Gtk.Orientation.VERTICAL}
        $={(self) => {
          setUpExit(self, upTo == 'power' ? powerButton : scanButton);
          list?.(self);
        }}
      >
        {children}
      </box>
    </scrolledwindow>
  </box>;
};
