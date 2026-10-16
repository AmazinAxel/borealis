import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { execAsync } from 'ags/process';
import inputControl from '../lib/inputControl';

let textBox: Gtk.Entry;

export default () => inputControl('emojiPicker', () =>
  <entry
    enableEmojiCompletion
    showEmojiIcon
    halign={Gtk.Align.CENTER}
    valign={Gtk.Align.CENTER}
    $={(self) => textBox = self}
    onNotifyText={({ text }) => {
      if (!text || /[:a-z]/.test(text)) return;
      app.get_window('emojiPicker')?.hide();
      execAsync(['wl-copy', '-t', 'text/plain', text]);
    }}
  />,
  { onShow: () => textBox.text = '', focus: () => textBox }
);
