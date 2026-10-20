import { execAsync } from 'ags/process';

const systemctl = (action: string) => () => void execAsync(['systemctl', action]).catch(() => { });

export const suspend = systemctl('suspend');
export const hibernate = systemctl('hibernate');
export const poweroff = systemctl('poweroff');
export const reboot = systemctl('reboot');
