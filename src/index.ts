import { registerPlugin } from '@capacitor/core';
import type { NativeTimerPlugin } from './definitions';

const NativeTimer = registerPlugin<NativeTimerPlugin>('NativeTimer', {
  web: () => import('./web').then(m => new m.NativeTimerWeb()),
});

export * from './definitions';
export { NativeTimer };
