import { WebPlugin } from '@capacitor/core';
import type { NativeTimerPlugin } from './definitions';

export class NativeTimerWeb extends WebPlugin implements NativeTimerPlugin {
  private startTime: number = 0;
  private isRunning: boolean = false;
  private interval?: number;

  async startTimer(options: { startTime: number; title: string; body: string }): Promise<{ success: boolean }> {
    console.log('NativeTimer Web: startTimer called', options);
    this.startTime = options.startTime;
    this.isRunning = true;
    
    // Simular actualizaciones para web
    this.interval = window.setInterval(() => {
      const elapsed = Date.now() - this.startTime;
      const hours = Math.floor(elapsed / 3600000);
      const minutes = Math.floor((elapsed % 3600000) / 60000);
      const seconds = Math.floor((elapsed % 60000) / 1000);
      const formattedTime = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
      
      this.notifyListeners('timerUpdate', { 
        elapsedTime: elapsed, 
        formattedTime 
      });
    }, 30000); // Cada 30 segundos

    return { success: true };
  }

  async stopTimer(): Promise<{ success: boolean }> {
    console.log('NativeTimer Web: stopTimer called');
    this.isRunning = false;
    if (this.interval) {
      window.clearInterval(this.interval);
      this.interval = undefined;
    }
    return { success: true };
  }

  async updateNotification(options: { title: string; body: string }): Promise<{ success: boolean }> {
    console.log('NativeTimer Web: updateNotification called', options);
    // En web, solo log
    return { success: true };
  }

  async isTimerRunning(): Promise<{ isRunning: boolean }> {
    return { isRunning: this.isRunning };
  }

  async getElapsedTime(): Promise<{ elapsedTime: number }> {
    if (!this.isRunning) return { elapsedTime: 0 };
    return { elapsedTime: Date.now() - this.startTime };
  }

  async setAppForegroundState(options: { inForeground: boolean }): Promise<{ success: boolean }> {
    console.log('NativeTimer Web: setAppForegroundState called', options);
    // En web no es necesario, pero implementamos para compatibilidad
    return { success: true };
  }

  async resetNotificationState(): Promise<{ success: boolean }> {
    console.log('NativeTimer Web: resetNotificationState called');
    // En web no es necesario, pero implementamos para compatibilidad  
    return { success: true };
  }

  // MARK: - Live Activities Support (iOS only - Web stubs)

  async areLiveActivitiesAvailable(): Promise<{ available: boolean }> {
    console.log('NativeTimer Web: areLiveActivitiesAvailable - not supported');
    return { available: false };
  }

  async startLiveActivity(options: {
    title: string;
    startTime: string;
    elapsedTime: string;
    status: string;
  }): Promise<{ success: boolean; activityId?: string }> {
    console.log('NativeTimer Web: startLiveActivity - not supported', options);
    return { success: false };
  }

  async updateLiveActivity(options: {
    activityId: string;
    elapsedTime: string;
    status: string;
  }): Promise<{ success: boolean }> {
    console.log('NativeTimer Web: updateLiveActivity - not supported', options);
    return { success: false };
  }

  async stopLiveActivity(options: { activityId: string }): Promise<{ success: boolean }> {
    console.log('NativeTimer Web: stopLiveActivity - not supported', options);
    return { success: false };
  }

  async stopAllLiveActivities(): Promise<{ success: boolean }> {
    console.log('NativeTimer Web: stopAllLiveActivities - not supported');
    return { success: false };
  }
}
