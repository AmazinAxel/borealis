import { subprocess, execAsync } from 'ags/process';

interface NotifyAction {
  id: number,
  label: string,
  command: string
}

interface NotifySendProps {
  title: string,
  body?: string,
  appName?: string,
  category?: string,
  actions?: NotifyAction[]
}

export const notifySend = ({
  title,
  body,
  appName,
  category,
  actions = []
}: NotifySendProps) => new Promise<number>((resolve) => {
  let printedId = false;

  const cmd = [
    'notify-send',
    '--print-id',
    ...(appName ? ['--app-name=' + appName] : []),
    ...(category ? ['--category=' + category] : []),
    ...actions.map(({ id, label }) => `--action=${id}=${label}`),
    title,
    body ?? '',
  ];

  subprocess(
    cmd,
    (out) => {
      if (!printedId) {
        resolve(parseInt(out));
        printedId = true;
        return;
      }
      const command = actions.find((a) => String(a.id) == out)?.command;
      if (command) execAsync(command).catch(() => { });
    }
  );
});
