import Wp from 'gi://AstalWp';
import { createBinding, createState, For } from 'ags';
import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import Pango from 'gi://Pango';
import { execAsync } from 'ags/process';
import { wp, audio, volumeIcon } from '../../../lib/audio';
import { idleOnce } from '../../../lib/idle';

const defaultSpeaker = createBinding(audio, 'defaultSpeaker');

const volume = createBinding(audio, 'defaultSpeaker', 'volume')((v) => v ?? 0);

export const VolumeSlider = () =>
  <box>
    <image iconName={volumeIcon} />
    <slider
      hexpand
      focusable={false}
      onChangeValue={({ value }) => {
        const speaker = audio.defaultSpeaker;
        if (!speaker) return;
        speaker.volume = value;
        speaker.mute = false;
      }}
      value={volume}
    />
  </box>;

const nameSubstitute = (name: string | null) => {
  if (!name) return '';
  if (name.includes('HD Audio Controller')) return name.split(' ').pop()!; // 'Speaker' or 'Headphones'
  if (name.includes('HDMI')) return 'Monitor'; // monitor has a speaker
  return name;
};

const speakersBind = createBinding(audio, 'speakers');
const speakers = () => audio.speakers ?? [];

const COMBINED = 'combined-bt-sink';
const isCombined = (s: Wp.Endpoint) => nodeName(s) == COMBINED;

const nodeName = (s: Wp.Endpoint) =>
  s.get_pw_property('node.name') ?? String(s.serial);

const isBluetooth = (s: Wp.Endpoint) => nodeName(s).startsWith('bluez_');
let linked: string[] = [];

let linkQueue: Promise<unknown> = Promise.resolve();

const link = (target: string, connect: boolean) => {
  linkQueue = linkQueue.then(() =>
    execAsync(['pw-link', ...(connect ? [] : ['-d']), COMBINED, target])
      .catch(() => { }));
};

const [ selected, setSelected ] = createState<string[]>([]);

const resolve = (names: string[]) => {
  const byName = new Map(speakers().map((s) => [nodeName(s), s]));
  return [...new Set(names)].flatMap((n) => byName.get(n) ?? []);
};

const applySelection = (names: string[]) => {
  const sinks = resolve(names);
  if (!sinks.length) return reconcileNow();

  const combined = speakers().find(isCombined);
  const want = sinks.length > 1 && combined ? sinks.map(nodeName) : [];

  for (const t of linked) if (!want.includes(t)) link(t, false);
  for (const n of want) if (!linked.includes(n)) link(n, true);
  linked = want;

  const target = want.length ? combined! : sinks[0];
  target.isDefault = true;
  setSelected(want.length ? want : [nodeName(sinks[0])]);
};

const reconcileNow = () => {
  if (linked.length > 1) return setSelected(linked);

  const def = audio.defaultSpeaker;
  if (def && !isCombined(def)) return setSelected([nodeName(def)]);

  const real = speakers().find((s) => !isCombined(s) && !isBluetooth(s))
    ?? speakers().find((s) => !isCombined(s));
  if (real) real.isDefault = true;
  else setSelected([]);
};

const reconcile = idleOnce(reconcileNow);

defaultSpeaker.subscribe(reconcile);

const watched = new Map<string, [Wp.Endpoint, number]>();
let firstWire = true;
const wire = () => {
  const wasFirst = firstWire;
  const present = new Set(speakers().map(nodeName));

  for (const [ name, [ sink, id ] ] of watched)
    if (!present.has(name)) {
      sink.disconnect(id);
      watched.delete(name);
    }

  let fresh: Wp.Endpoint | null = null;
  for (const s of speakers()) {
    const name = nodeName(s);
    if (watched.has(name)) continue;
    watched.set(name, [s, s.connect('notify::is-default', reconcile)]);
    if (isBluetooth(s)) fresh = s;
  }

  const survivors = linked.filter((n) => present.has(n));
  const collapsed = survivors.length != linked.length;
  if (collapsed) {
    linked = [];
    for (const n of survivors) link(n, false);
  }
  firstWire = false;
  if (collapsed && survivors.length) return applySelection(survivors);

  if (fresh && !wasFirst && linked.length < 2) applySelection([nodeName(fresh)]);
  reconcile();
};
speakersBind.subscribe(wire);

wire();
wp.connect('ready', wire);

const toggleSink = (sink: Wp.Endpoint) => {
  const current = selected.peek();
  const name = nodeName(sink);
  applySelection(current.includes(name)
    ? current.filter((n) => n != name)
    : [...current, name]);
};

export const SinkSelector = () =>
  <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['sinkSelector']}
    onMap={(self) => self.get_first_child()?.grab_focus()}
  >
    <For each={speakersBind((all) => (all ?? []).filter((s) => !isCombined(s)))}>
      {(speaker: Wp.Endpoint) => {
        const isSelected = selected((names) => names.includes(nodeName(speaker)));
        return <button
          canTarget={false}
          onClicked={() => applySelection([nodeName(speaker)])}
          cssClasses={isSelected((v) => v ? ['active'] : [])}
        >
          <Gtk.EventControllerKey
            propagationPhase={Gtk.PropagationPhase.CAPTURE}
            onKeyPressed={(_, keyval, __, mod) => {
              const enter = keyval == Gdk.KEY_Return || keyval == Gdk.KEY_KP_Enter;
              if (!enter || !(mod & Gdk.ModifierType.SHIFT_MASK)) return false;
              toggleSink(speaker);
              return true;
            }}
          />
          <box>
            <image visible={isSelected} iconName="emblem-default-symbolic" marginEnd={7} />
            <label xalign={0} hexpand label={nameSubstitute(speaker.description)} ellipsize={Pango.EllipsizeMode.END} maxWidthChars={1} />
          </box>
        </button>
      }}
    </For>
  </box>
