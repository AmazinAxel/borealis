import { Gtk } from "ags/gtk4"
import { createState, type Accessor } from "ags"
import { timeout } from "ags/time"

export const createFlash = (ms: number) => {
    const [ visible, setVisible ] = createState(false);
    const [ reveal, setReveal ] = createState(false);
    let count = 0;
    const show = () => {
        setVisible(true);
        setReveal(true);
        count++;
        timeout(ms, () => --count === 0 && setReveal(false));
    };
    return { visible, reveal, show, onHidden: () => count === 0 && setVisible(false) };
};

export default ({ reveal, duration, type, onHidden, children }: {
    reveal: Accessor<boolean>,
    duration: number,
    type: Gtk.RevealerTransitionType,
    onHidden?: () => void,
    children: JSX.Element
}) =>
    <revealer
        revealChild={reveal}
        transitionDuration={reveal((r) => r ? duration : 0)}
        transitionType={type}
        onNotifyChildRevealed={(self) => (!self.childRevealed) && onHidden?.()}
    >
        {children}
    </revealer>
