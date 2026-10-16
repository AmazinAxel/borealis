import { Astal, Gtk } from 'ags/gtk4';
import { createComputed, createState, For, This, onCleanup } from 'ags';
import { createSubprocess, execAsync } from 'ags/process';
const { TOP, LEFT } = Astal.WindowAnchor;
import app from 'ags/gtk4/app';
import { monitors } from '../lib/monitors';
import OutTransition, { createFlash } from '../lib/outTransition';

const IDS = [...Array(9).keys()].map((i) => i + 1);

const [ focused, setFocused ] = createState(0);
const [ occupied, setOccupied ] = createState(new Set<number>());
const [ scratchpad, setScratchpad ] = createState(0);
const { visible, reveal, show, onHidden } = createFlash(400);

const updateWorkspaces = () =>
  execAsync(['swaymsg', '-t', 'get_workspaces', '-r'])
    .then((out) => {
      const list: { num: number, focused: boolean }[] = JSON.parse(out);
      setOccupied(new Set(list.map((w) => w.num).filter((n) => IDS.includes(n))));

      setFocused(list.find((w) => w.focused)?.num ?? 0);
    })
    .catch(() => {});

const updateScratchpad = () =>
  execAsync(['swaymsg', '-t', 'get_tree', '-r'])
    .then((out) => {
      const scratch = JSON.parse(out).nodes
        ?.find((o: any) => o.name === '__i3')
        ?.nodes?.find((w: any) => w.name === '__i3_scratch');
      setScratchpad(scratch?.floating_nodes?.length ?? 0);
    })
    .catch(() => {});

const eventStream = createSubprocess('', ['swaymsg', '-t', 'subscribe', '-m', '["workspace"]']);
eventStream.subscribe(() => { // Show workspaces on workspace change
  updateWorkspaces();
  updateScratchpad();
  show();
});
updateWorkspaces();
updateScratchpad();

export default () =>
  <For each={monitors}>
    {(monitor) => <This this={app}>
      <window
        name="workspaces"
        anchor={TOP | LEFT}
        layer={Astal.Layer.OVERLAY}
        gdkmonitor={monitor}
        application={app}
        visible={visible}
        $={(self) => onCleanup(() => self.destroy())}
        defaultHeight={1} // gtk layer shell glitch workaround
        defaultWidth={1}
      >
        <OutTransition duration={150} reveal={reveal} onHidden={onHidden} type={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
          <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['statusElement']}>
            {IDS.map((id) =>
              <box cssClasses={createComputed((track) => track(focused) === id
                ? ['workspace', 'active']
                : track(occupied).has(id)
                  ? ['workspace', 'occupied']
                  : ['workspace'])}/>
            )}
            <label
              cssClasses={['scratchpad']}
              visible={scratchpad((c) => c > 0)}
              label={scratchpad(String)}
            />
          </box>
        </OutTransition>
      </window>
    </This>}
  </For>;
