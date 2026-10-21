import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';

export default (ctrl: Gtk.EventControllerScroll, dy: number, wheel: number, smooth: number) =>
  ctrl.get_unit() == Gdk.ScrollUnit.WHEEL ? Math.sign(dy) * wheel : dy * smooth;
