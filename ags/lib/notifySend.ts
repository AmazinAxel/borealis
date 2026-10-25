import { subprocess, execAsync } from 'ags/process';

export const notifySend = ({ title, body = '', appName, category, actions = [] }: {
  title: string,
  body?: string,
  appName?: string,
  category?: string,
  actions?: { id: number, label: string, command: string }[],
}) => new Promise<number>((resolve) => {
  let printedId = false;
  subprocess([
    'notify-send',
    '--print-id',
    ...(appName ? ['--app-name=' + appName] : []),
    ...(category ? ['--category=' + category] : []),
    ...actions.map(({ id, label }) => `--action=${id}=${label}`),
    title,
    body,
  ], (out) => {
    if (!printedId) {
      printedId = true;
      return resolve(parseInt(out));
    }
    const command = actions.find((a) => String(a.id) == out)?.command;
    if (command) execAsync(command).catch(() => { });
  });
});
