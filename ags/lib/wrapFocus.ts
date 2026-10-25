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

const upExits = new WeakMap<Gtk.Widget, Gtk.Widget>();
export const setUpExit = (from: Gtk.Widget, to: Gtk.Widget) => upExits.set(from, to);

const upExit = (w: Gtk.Widget | null) => {
  for (; w; w = w.get_parent()) {
    const to = upExits.get(w);
    if (to) return { from: w, to };
  }
  return null;
};

export const wrapIndex = (i: number, delta: number, len: number) =>
  ((i < 0 && delta < 0 ? 0 : i) + delta + len) % len;

export default (ctrl: Gtk.EventControllerKey, key: number, _keycode: number, state: Gdk.ModifierType) => {
  const win = ctrl.get_widget() as Gtk.Window;
  const dir = dirs[key];
  const focus = win.get_focus();
  if (!dir || !focus || focus.get_native() !== win
    || (state & (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.ALT_MASK | Gdk.ModifierType.SHIFT_MASK))
    || ownsArrows(focus, dir[0] == LEFT || dir[0] == RIGHT)) return false;

  const exit = dir[0] == UP ? upExit(focus) : null;
  if (!win.child_focus(dir[0]))
    for (let i = 0; i < 1000 && win.child_focus(dir[1]); i++);
  if (exit && !win.get_focus()?.is_ancestor(exit.from)) exit.to.grab_focus();

  return true;
};
