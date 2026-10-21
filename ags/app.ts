import style from './style.css';
import searchableDialogStyle from './lib/searchableDialog.css';
import clipboardStyle from './widgets/clipboard/clipboard.css';
import statusStyle from './widgets/status/status.css';
import notificationStyle from './widgets/notifications/notifications.css';
import osdStyle from './widgets/osd/osd.css';
import lockscreenStyle from './widgets/lockscreen/lockscreen.css';

import app from 'ags/gtk4/app';
import { Gtk } from 'ags/gtk4';
import { execAsync } from 'ags/process';

import status, { setStatusMargin } from './widgets/status/status';
import sideview, { showPage, closeSideview, hideSideview, toggleSideviewFocus, toggleSideviewSize } from './widgets/sideview';
import clipboard from './widgets/clipboard/clipboard';
import compress from './widgets/clipboard/compress';
import emojiPicker from './widgets/emojiPicker';
import launcher from './widgets/launcher/launcher';
import { focusMenu, focusTask, toggleFocus } from './widgets/focus';
import pass from './widgets/pass/pass';
import passSave from './widgets/pass/passSave';
import recordMenu from './widgets/record/record';
import { notifications, clearOldestNotification, invokeOldestNotification } from './widgets/notifications/notifications';
import osd from './widgets/osd/osd';
import powermenu from './widgets/powermenu/powermenu';
import { notifySend } from './lib/notifySend';
import { isRec, stopRec, startClippingService } from './widgets/record/service';

import { lockScreen } from './widgets/lockscreen/lockscreen';
import { monitorBrightness } from './lib/brightness';
import { initMedia, updTrack, playPause, chngPlaylist } from './lib/mediaPlayer';
import wallpaper, { randomWallpaper } from './lib/wallpaper';
import { readFileAsync } from 'ags/file';
import { streamingMode, setStreamingMode } from './lib/streamingMode';
import workspaces from './widgets/workspaces';
import asideStatusWindow from './lib/asideStatusWindow';
import { setAsideWindow, closeAsideWindow } from './lib/asideState';

const media: Record<string, () => void> = {
  next: () => updTrack('next'),
  prev: () => updTrack('prev'),
  toggle: playPause,
  nextPlaylist: () => chngPlaylist('next'),
  prevPlaylist: () => chngPlaylist('prev'),
};

const requests: Record<string, (arg?: string) => void> = {
  hideNotif: clearOldestNotification,
  randomWallpaper,
  lock: lockScreen,
  invokeOldestNotif: (arg) => invokeOldestNotification(Number(arg ?? 0)),
  toggleSideviewSize,
  sideviewPlan: () => showPage('plan'),
  sideviewClaude: () => showPage('claude'),
  sideviewCustom: () => showPage('custom'),
  closeSideview,
  hideSideview,
  toggleSideviewFocus,
  record: () => isRec.peek() ? stopRec() : app.toggle_window('recordMenu'),
  media: (arg) => media[arg ?? '']?.(),
  toggleQuicksettings: () => setAsideWindow('quickSettings'),
  toggleCalendar: () => setAsideWindow('calendar'),
  toggleBluetooth: () => setAsideWindow('bluetooth'),
  toggleWifi: () => setAsideWindow('wifi'),
  closeAsideStatusMenuWidget: closeAsideWindow,
  toggleInfoArea: () => {
    app.toggle_window('status');
    const status = app.get_window('status')!;
    setStatusMargin(status.visible ? status.measure(Gtk.Orientation.HORIZONTAL, -1)[1] : 0);
  },
  toggleStreamingMode: () => setStreamingMode(!streamingMode.peek()),
  toggleFocus,
};

const reminders = async () => {
  const lastSync = Number(await readFileAsync('/home/alec/Projects/flake/ags/lastSync.txt').catch(() => 0));

  if ((Date.now() - lastSync) > 540000000) { // Last sync was ~7 days ago
    notifySend({
      appName: 'Sync',
      title: 'Sync system',
      actions: [{
        id: 1,
        label: 'Update & Sync',
        command: `footclient -e fish -c 'sys-sync; echo "Press a key to exit"; read --nchars=1'`,
      }],
    });
    return;
  }

  const folderSize = await execAsync(['du', '-sb', '/home/alec/Downloads'])
    .then((out) => parseInt(out)).catch(() => 0);
  if (folderSize > 100000000) { // Greater than 100MB
    notifySend({
      appName: 'Cleanup',
      title: 'Empty Downloads',
      actions: [{ id: 1, label: 'View folder', command: 'nemo /home/alec/Downloads' }],
    });
  }
};

app.start({
  css: style + searchableDialogStyle + clipboardStyle + statusStyle + notificationStyle + osdStyle + lockscreenStyle,
  main() {
    Gtk.Settings.get_default()!.gtkImModule = 'simple'; // fix launcher errors

    wallpaper();
    randomWallpaper();
    status();
    sideview();
    clipboard();
    compress();
    emojiPicker();
    recordMenu();
    focusMenu();
    focusTask();
    osd();
    powermenu();
    asideStatusWindow();
    workspaces();
    notifications();
    launcher();
    pass();
    passSave();

    monitorBrightness();
    initMedia();
    reminders();
    startClippingService();
  },
  requestHandler(argv, respond) {
    const [ cmd, arg ] = argv.join(' ').split(' ');
    try {
      requests[cmd]?.(arg);
    } catch { }
    respond('');
  },
});
