import { createBinding } from 'ags';
import app from 'ags/gtk4/app';

export const monitors = createBinding(app, 'monitors');
