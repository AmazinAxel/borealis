import { createState } from 'ags';
import { Gtk } from 'ags/gtk4';
import idle from './idle';

export const [ currentAsideWindow, setCurrentAsideWindow ] = createState<string | null>(null);

export const setAsideWindow = (name: string) => setCurrentAsideWindow(currentAsideWindow.peek() === name ? null : name);

export const closeAsideWindow = () => setCurrentAsideWindow(null); // null hides

export const focusAside = (name: string, target: () => Gtk.Widget | null | undefined) => idle(() => {
  const widget = currentAsideWindow.peek() === name && target();
  if (widget && widget.get_mapped()) widget.grab_focus();
});
