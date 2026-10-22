import { Astal, Gtk } from 'ags/gtk4';
import { createComputed, createState } from 'ags';
import { swaySubscribe, swayTree } from '../lib/sway';
const { TOP, LEFT } = Astal.WindowAnchor;
import app from 'ags/gtk4/app';
import perMonitor from '../lib/perMonitor';
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
  swayTree<SwayNode>()
    .then((tree) => {
      if (id != request) return;
      const workspaces = tree.nodes.flatMap((o) => o.nodes);
      setOccupied(new Set(workspaces.map((w) => w.num ?? 0).filter((n) => IDS.includes(n))));

      const output = tree.nodes.find((o) => o.id == tree.focus[0]);
      setFocused(output?.nodes.find((w) => w.id == output.focus[0])?.num ?? 0);
      setScratchpad(workspaces.find((w) => w.name == '__i3_scratch')?.floating_nodes.length ?? 0);
    })
    .catch(() => { });
};

swaySubscribe(['workspace'], (event) => { // Show workspaces on workspace change
  const { change, current, old } = event as { change: string, current?: SwayNode, old?: SwayNode };
  if (change == 'focus' && current?.num) {
    const next = new Set(occupied.peek());
    if (old?.num && !old.nodes.length && !old.floating_nodes.length) next.delete(old.num);
    setOccupied(next);
    setFocused(current.num);
  }
  updateWorkspaces();
  show();
});
updateWorkspaces();

export default () => perMonitor((monitor) =>
  <window
    name="workspaces"
    anchor={TOP | LEFT}
    layer={Astal.Layer.OVERLAY}
    gdkmonitor={monitor}
    application={app}
    visible={visible}
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
  </window>);
