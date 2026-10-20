import { Gtk } from 'ags/gtk4';
import { formatNow } from '../../../lib/time';

export const Time = () =>
  <box orientation={Gtk.Orientation.VERTICAL} hexpand cssClasses={['time', 'timeSection']}>
    <label cssClasses={['date']} label={formatNow('%m')} />
    <label cssClasses={['date', 'bottom']} label={formatNow('%d')} />
    <label cssClasses={['time']} label={formatNow('%H\n%M')} />
    <label cssClasses={['day']} label={formatNow('%a')} />
  </box>;
