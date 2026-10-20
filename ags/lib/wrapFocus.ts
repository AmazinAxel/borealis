import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';

const { UP, DOWN, LEFT, RIGHT } = Gtk.DirectionType;
const dirs: Record<number, [Gtk.DirectionType, Gtk.DirectionType]> = {
  [Gdk.KEY_Up]: [UP, DOWN],
  [Gdk.KEY_Down]: [DOWN, UP],
  [Gdk.KEY_Left]: [LEFT, RIGHT],
  [Gdk.KEY_Right]: [RIGHT, LEFT],
};

const ownsArrows = (w: Gtk.Widget | null, horizontal: boolean) => {
  for (; w; w = w.get_parent())
    if (w instanceof Gtk.Range || w instanceof Gtk.Calendar || (horizontal && w instanceof Gtk.Text)) return true;
  return false;
};

export default (ctrl: Gtk.EventControllerKey, key: number, _keycode: number, state: Gdk.ModifierType) => {
  const win = ctrl.get_widget() as Gtk.Window;
  const dir = dirs[key];
  const focus = win.get_focus();
  if (!dir || !focus || focus.get_native() !== win
    || (state & (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.ALT_MASK | Gdk.ModifierType.SHIFT_MASK))
    || ownsArrows(focus, dir[0] == LEFT || dir[0] == RIGHT)) return false;

  if (!win.child_focus(dir[0]))
    for (let i = 0; i < 1000 && win.child_focus(dir[1]); i++);

  const row = win.get_focus()?.get_ancestor(Gtk.ListBoxRow.$gtype) as Gtk.ListBoxRow | null;
  (row?.get_parent() as Gtk.ListBox | null)?.select_row(row);
  return true;
};
