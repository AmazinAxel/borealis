import { createState } from "ags"

export const [ currentAsideWindow, setCurrentAsideWindow ] = createState<string | null>(null);

export const setAsideWindow = (name: string) => setCurrentAsideWindow(currentAsideWindow.peek() === name ? null : name);

export const closeAsideWindow = () => setCurrentAsideWindow(null); // null hides
