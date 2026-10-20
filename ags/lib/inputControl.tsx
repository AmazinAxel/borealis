import app from 'ags/gtk4/app';
import { Astal, Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import wrapFocus from './wrapFocus';
const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

type Options = {
  onShow?: () => void,
  searchable?: boolean,
  onKeyPressed?: (ctrl: Gtk.EventControllerKey, key: number, keycode: number, state: Gdk.ModifierType) => boolean | void,
  keymode?: Astal.Keymode,
  layer?: Astal.Layer,
  focus?: () => Gtk.Entry,
};

export default (windowName: string, Child: () => JSX.Element, {
  onShow, searchable, onKeyPressed, keymode = Astal.Keymode.EXCLUSIVE, layer = Astal.Layer.OVERLAY, focus,
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
      target.grab_focus();
      target.set_position(-1); // cursor pos
    }}
    cssClasses={searchable ? ['backgroundDim', 'searchableDialog'] : ['backgroundDim']}
  >
    <Gtk.EventControllerKey
      propagationPhase={Gtk.PropagationPhase.CAPTURE}
      onKeyPressed={(ctrl, key, keycode, state) => {
        if (key == Gdk.KEY_Escape) { app.toggle_window(windowName); return true; }
        return onKeyPressed?.(ctrl, key, keycode, state) || wrapFocus(ctrl, key, keycode, state);
      }} />
    <Child />
  </window>;
