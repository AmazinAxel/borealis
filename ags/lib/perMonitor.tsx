import { createBinding, For, This, onCleanup } from 'ags';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Gdk from 'gi://Gdk';

export default (window: (monitor: Gdk.Monitor) => JSX.Element) =>
  <For each={createBinding(app, 'monitors')}>
    {(monitor: Gdk.Monitor) => {
      const win = window(monitor) as Gtk.Window;
      onCleanup(() => win.destroy());
      return <This this={app}>{win}</This>;
    }}
  </For>;
