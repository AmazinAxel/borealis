import { Gtk } from 'ags/gtk4';
import { createComputed, type Accessor } from 'ags';
import { setUpExit } from './wrapFocus';

export default ({ powered, powerIcon, scanning, scanSensitive, empty, upTo, onPower, onScan, power, scan, list, children }: {
  powered: Accessor<boolean>,
  powerIcon: string | Accessor<string>,
  scanning: Accessor<boolean>,
  scanSensitive?: Accessor<boolean>,
  empty?: Accessor<boolean>,
  upTo: 'power' | 'scan',
  onPower: () => void,
  onScan: () => void,
  power?: (self: Gtk.Button) => void,
  scan?: (self: Gtk.Button) => void,
  list?: (self: Gtk.Box) => void,
  children: JSX.Element,
}) => {
  let powerButton: Gtk.Button, scanButton: Gtk.Button;
  const showList = createComputed((track) => track(powered) && !(empty && track(empty)));
  return <box orientation={Gtk.Orientation.VERTICAL}>
    <box>
      <button
        canTarget={false}
        hexpand halign={powered((on) => on ? Gtk.Align.START : Gtk.Align.CENTER)}
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
    <Gtk.Separator visible={showList} />
    <scrolledwindow
      hscrollbarPolicy={Gtk.PolicyType.NEVER}
      hexpand vexpand
      propagateNaturalWidth propagateNaturalHeight
      maxContentHeight={500}
      visible={showList}
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
