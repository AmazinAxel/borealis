import { createState, For, type Accessor } from 'ags';
import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import BackgroundSection from './backgroundSection';
import inputControl from './inputControl';
import { wrapIndex } from './wrapFocus';

export default <T,>(name: string, { placeholder, search, activate, row, sensitive, onShow }: {
  placeholder: string,
  search: (text: string) => T[],
  activate: (item: T) => void,
  row: (item: T) => JSX.Element,
  sensitive?: (item: T) => Accessor<boolean>,
  onShow?: () => void,
}) => {
  let textBox: Gtk.Entry;
  const [ items, setItems ] = createState<T[]>([]);
  const [ selected, setSelected ] = createState<T | undefined>(undefined);

  const handleKeys = (_ctrl: Gtk.EventControllerKey, key: number) => {
    if (key != Gdk.KEY_Up && key != Gdk.KEY_Down) return false;
    const list = items.peek();
    if (list.length) setSelected(list[wrapIndex(list.indexOf(selected.peek()!), key == Gdk.KEY_Down ? 1 : -1, list.length)]);
    return true;
  };

  return inputControl(name, () =>
    <BackgroundSection
      height={700} width={500}
      header={<entry
        $type="overlay"
        primaryIconName="system-search-symbolic"
        placeholderText={placeholder}
        onNotifyText={({ text }) => {
          const list = search(text);
          setItems(list);
          setSelected(list[0]);
        }}
        onActivate={() => {
          const top = selected.peek();
          if (top !== undefined) activate(top);
        }}
        $={(self) => textBox = self} />}
      content={<box spacing={6} marginTop={6} orientation={Gtk.Orientation.VERTICAL} visible={items((l) => l.length > 0)}>
        <For each={items}>
          {(item) =>
            <button
              canTarget={false}
              onClicked={() => activate(item)}
              sensitive={sensitive?.(item) ?? true}
              cssClasses={selected((s) => s === item ? ['button', 'selected'] : ['button'])}
            >
              {row(item)}
            </button>}
        </For>
      </box>}
    />,
    { onShow, onKeyPressed: handleKeys, searchable: true, focus: () => textBox });
};
