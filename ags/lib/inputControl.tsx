import app from 'ags/gtk4/app';
import { Astal, Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import wrapFocus from './wrapFocus';
const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

export type Actions = Record<number, () => void>;

type Options = {
  onShow?: () => void,
  searchable?: boolean,
  actions?: Actions,
  ctrlActions?: Actions,
  onKeyPressed?: (ctrl: Gtk.EventControllerKey, key: number, keycode: number, state: Gdk.ModifierType) => boolean | void,
  keymode?: Astal.Keymode,
  layer?: Astal.Layer,
  focus?: () => Gtk.Entry,
};

export default (windowName: string, Child: () => JSX.Element, {
  onShow, searchable, actions, ctrlActions, onKeyPressed, keymode = Astal.Keymode.EXCLUSIVE, layer = Astal.Layer.OVERLAY, focus,
}: Options = {}) =>
  <window
    name={windowName}
    namespace={windowName}
    keymode={keymode}
    anchor={TOP | BOTTOM | LEFT | RIGHT}
    application={app}
    layer={layer}
    onShow={() => {
      onShow?.();
      const target = focus?.();
      if (!target) return;
      target.text = '';
      target.grab_focus();
    }}
    cssClasses={searchable ? ['backgroundDim', 'searchableDialog'] : ['backgroundDim']}
  >
    <Gtk.EventControllerKey
      propagationPhase={Gtk.PropagationPhase.CAPTURE}
      onKeyPressed={(ctrl, key, keycode, state) => {
        if (key == Gdk.KEY_Escape) { app.toggle_window(windowName); return true; }
        const lower = Gdk.keyval_to_lower(key);
        const action = actions?.[lower] ?? (state & Gdk.ModifierType.CONTROL_MASK ? ctrlActions?.[lower] : undefined);
        if (action) { action(); return true; }
        return onKeyPressed?.(ctrl, key, keycode, state) || wrapFocus(ctrl, key, keycode, state);
      }} />
    <Child />
  </window>;
