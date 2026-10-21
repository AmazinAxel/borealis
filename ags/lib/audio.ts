import Wp from 'gi://AstalWp';
import { createBinding } from 'ags';

export const wp = Wp.get_default()!;
export const audio = wp.audio;
export const volumeIcon = createBinding(audio, 'defaultSpeaker', 'volumeIcon')((i) => i ?? 'audio-volume-muted-symbolic');
