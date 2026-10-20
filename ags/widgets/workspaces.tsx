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

type SwayNode = { id: number, num?: number, name: string, focus: number[], nodes: SwayNode[], floating_nodes: SwayNode[] };

let request = 0;
const updateWorkspaces = () => {
  const id = ++request;
  execAsync(['swaymsg', '-t', 'get_tree', '-r'])
    .then((out) => {
      if (id != request) return;
      const tree = JSON.parse(out) as SwayNode;
      const workspaces = tree.nodes.flatMap((o) => o.nodes);
      setOccupied(new Set(workspaces.map((w) => w.num ?? 0).filter((n) => IDS.includes(n))));

      const output = tree.nodes.find((o) => o.id == tree.focus[0]);
      setFocused(output?.nodes.find((w) => w.id == output.focus[0])?.num ?? 0);
      setScratchpad(workspaces.find((w) => w.name == '__i3_scratch')?.floating_nodes.length ?? 0);
    })
    .catch(() => { });
};

const eventStream = createSubprocess('', ['swaymsg', '-t', 'subscribe', '-m', '["workspace"]']);
eventStream.subscribe(() => { // Show workspaces on workspace change
  updateWorkspaces();
  show();
});
updateWorkspaces();

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
        resizable={false}
      >
        <OutTransition duration={150} reveal={reveal} onHidden={onHidden} type={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
          <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['statusElement']}>
            {IDS.map((id) =>
              <box cssClasses={createComputed((track) => track(focused) === id
                ? ['workspace', 'active']
                : track(occupied).has(id)
                  ? ['workspace', 'occupied']
                  : ['workspace'])} />
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
