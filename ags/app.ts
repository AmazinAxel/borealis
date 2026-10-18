import style from './style.css';
import searchableDialogStyle from './lib/searchableDialog.css';
import clipboardStyle from './widgets/clipboard/clipboard.css';
import statusStyle from './widgets/status/status.css';
import notificationStyle from './widgets/notifications/notifications.css';
import osdStyle from './widgets/osd/osd.css';
import lockscreenStyle from './widgets/lockscreen/lockscreen.css';

import app from "ags/gtk4/app"
import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process";
import astalIO from "gi://AstalIO"

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
import { notifications, clearOldestNotification, invokeOldestNotification, streamingMode, setStreamingMode } from './widgets/notifications/notifications';
import osd from './widgets/osd/osd';
import powermenu from './widgets/powermenu/powermenu';
import { notifySend } from './lib/notifySend';
import { isRec, stopRec, startClippingService } from './widgets/record/service';

import { lockScreen } from './widgets/lockscreen/lockscreen';
import { monitorBrightness } from './lib/brightness';
import { initMedia, updTrack, playPause, chngPlaylist, randomWallpaper } from './lib/mediaPlayer';
import workspaces from './widgets/workspaces';
import asideStatusWindow from './lib/asideStatusWindow';
import { setAsideWindow, closeAsideWindow } from './lib/asideState';

let blueLightFilter = true;

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
    record: () => isRec.peek() ? stopRec() : app.toggle_window("recordMenu"),
    media: (arg) => media[arg ?? '']?.(),
    toggleQuicksettings: () => setAsideWindow('quickSettings'),
    toggleCalendar: () => setAsideWindow('calendar'),
    toggleBluetooth: () => setAsideWindow('bluetooth'),
    toggleWifi: () => setAsideWindow('wifi'),
    closeAsideStatusMenuWidget: closeAsideWindow,
    toggleInfoArea: () => {
        setStatusMargin(app.get_window('status')?.visible ? 0 : 41);
        app.toggle_window('status');
    },
    toggleStreamingMode: () => setStreamingMode(!streamingMode.peek()),
    toggleFocus,
    toggleFilter: () => {
        blueLightFilter = !blueLightFilter;
        execAsync(`busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q ${blueLightFilter ? 3500 : 6500}`);
    },
};


app.start({
    css: style + searchableDialogStyle + clipboardStyle + statusStyle + notificationStyle + osdStyle + lockscreenStyle,
    main() {
        Gtk.Settings.get_default()!.gtkImModule = "simple"; // fix launcher errors

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

        monitorBrightness();
        notifications();
        initMedia();
        reminders();

        launcher();
        pass();
        passSave();
        startClippingService(); // Run last so if not installed it wont impact start
    },
    requestHandler(req, res) {
        const [ cmd, arg ] = req[0].split(" ");
        try {
            requests[cmd]?.(arg);
        } finally {
            res("Request handled successfully");
        };
    }
});

const reminders = async () => {
    const lastSync = Number(astalIO.read_file("/home/alec/Projects/flake/ags/lastSync.txt"));

    if ((Date.now() - lastSync) > 540000000) { // Last sync was ~7 days ago
        notifySend({
            appName: 'Sync',
            title: 'Sync system',
            actions: [{
                id: 1,
                label: 'Update & Sync',
                command: `footclient -e fish -c 'sys-sync; echo "Press a key to exit"; read --nchars=1'`
            }]
        });
        return;
    };

    const folderSize = await execAsync(['du', '-sb', '/home/alec/Downloads'])
        .then((out) => parseInt(out)).catch(() => 0);
    if (folderSize > 100000000) { // Greater than 100MB
        notifySend({
            appName: 'Cleanup',
            title: 'Empty Downloads',
            actions: [{
                id: 1,
                label: 'View folder',
                command: 'nemo /home/alec/Downloads'
            }]
        });
    };
};
