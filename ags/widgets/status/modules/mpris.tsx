import { createBinding } from 'ags';
import MprisService from 'gi://AstalMpris';

const mpris = MprisService.get_default();
const mprisPlayerBind = createBinding(mpris, 'players');

export const Mpris = () =>
  <box name="mprisBtn" visible={mprisPlayerBind((players) => players.length > 0)}>
    <image iconName="folder-music-symbolic" hexpand />
  </box>;
