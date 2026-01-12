import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Permissions } from '@kit.AbilityKit';
import PermissionHelper from '../common/PermissionHelper';
import { notificationManager } from '@kit.NotificationKit';
import vibrator from '@ohos.vibrator';
import { StartView } from './StartView';
import { ReportsView } from './ReportsView';
import { DashboardView } from './DashboardView';
import { secureRandomInt } from '../common/SecureRandom';
const SENSOR_INTERVAL = 200_000_000;
const MOCK_MODE = true;
const ADVICE_INTERVAL_MS = 60000;
@Entry
@Component
struct Index {
  @State sensorsActive: boolean = false;
  @State showStartScreen: boolean = true;
  @State showReports: boolean = false;
  @State heartRate: number = 0;
  @State temperature: number = 0;
  @State pressure: number = 0;
  @State steps: number = 0;
  @State motionLevel: string = 'Unknown';
  showPopup: boolean = false;
  @State statusLabel: string = 'Initializing...';
  @State adviceText: string = 'Sensors are starting, please wait.';
  @State reportHRMax: number = 0;
  @State reportHRMin: number = 999;
  private reportHRSum: number = 0;
  private reportHRCount: number = 0;
  private reportStepStart: number = 0;
  private reportStepEnd: number = 0;
  @State reportTempMax: number = 0;
  @State reportTempMin: number = 100;
  @State activeMinutes: number = 0;
  @State restMinutes: number = 0;
  private lastActivityCheck: number = Date.now();
  private lastAdviceTime: number = 0;
  private mockTimer: number = 0;
  aboutToAppear(): void {
    if (MOCK_MODE) {
      this.startMockValues();
      this.statusLabel = 'Mock Mode Active';
      this.adviceText = 'Mock sensor values running.';
      return;
    }
    this.initPermissions().then(ok => {
      if (!ok) {
        this.statusLabel = 'Permission required';
        this.adviceText = 'Please grant sensor permissions on the watch.';
        return;
      }
      this.startSensors();
    });
  }
  aboutToDisappear(): void {
    if (MOCK_MODE) {
      clearInterval(this.mockTimer);
      return;
    }
    try { sensor.off(sensor.SensorId.ACCELEROMETER); } catch (_) {}
    try { sensor.off(sensor.SensorId.HEART_RATE); } catch (_) {}
    try { sensor.off(sensor.SensorId.PEDOMETER); } catch (_) {}
    try { sensor.off(sensor.SensorId.BAROMETER); } catch (_) {}
    try { sensor.off(sensor.SensorId.AMBIENT_TEMPERATURE); } catch (_) {}
  }
  private startMockValues(): void {
    clearInterval(this.mockTimer);
    this.mockTimer = setInterval(async () => {
      this.heartRate = await secureRandomInt(60, 139);
      this.temperature = await secureRandomInt(36, 38);
      this.pressure = await secureRandomInt(1000, 1020);
      this.steps += await secureRandomInt(0, 19);
      const idx: number = await secureRandomInt(0, 2);
      this.motionLevel = ['Resting', 'Light', 'Active'][idx];
      this.updateAdvice();
    }, 600);
  }
  private async initPermissions(): Promise<boolean> {
    const perms: Array<Permissions> = [
      'ohos.permission.ACCELEROMETER',
      'ohos.permission.ACTIVITY_MOTION',
      'ohos.permission.READ_HEALTH_DATA'
    ];
    return await PermissionHelper.requestPermissions(perms);
  }
  private startSensors(): void {
    this.statusLabel = 'Live';
    this.adviceText = 'Reading your signals...';

    this.subscribeAccelerometer();
    this.subscribeHeartRate();
    this.subscribeSteps();
    this.subscribePressure();
    this.subscribeTemperature();
  }
  private subscribeAccelerometer(): void {
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        const m = Math.sqrt(data.x * data.x + data.y * data.y + data.z * data.z);
        if (m < 1.05 * 9.81) {
          this.motionLevel = 'Resting';
        } else if (m < 1.4 * 9.81) {
          this.motionLevel = 'Light';
        } else {
          this.motionLevel = 'Active';
        }
        this.updateAdvice('normal');
      }, { interval: SENSOR_INTERVAL });
    } catch (_) {}
  }
  private subscribeHeartRate(): void {
    try {
      sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
        if (data.heartRate) {
          const prev = this.heartRate;
          this.heartRate = data.heartRate;

          const diff = Math.abs(this.heartRate - prev);
          const suddenJump = prev > 0 && diff >= 25;
          if (suddenJump || this.heartRate >= 150) {
            this.updateAdvice('sudden');
          } else {
            this.updateAdvice('normal');
          }
        }
      }, { interval: SENSOR_INTERVAL });
    } catch (_) {}
  }
  private subscribeSteps(): void {
    try {
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse) => {
        this.steps = data.steps;
        this.updateAdvice('normal');
      });
    } catch (_) {}
  }
  private subscribePressure(): void {
    try {
      sensor.on(sensor.SensorId.BAROMETER, (data: sensor.BarometerResponse) => {
        this.pressure = data.pressure;
        this.updateAdvice('normal');
      }, { interval: SENSOR_INTERVAL });
    } catch (_) {}
  }
  private subscribeTemperature(): void {
    try {
      sensor.on(sensor.SensorId.AMBIENT_TEMPERATURE, (data: sensor.AmbientTemperatureResponse) => {
        this.temperature = data.temperature;
        this.updateAdvice('normal');
      }, { interval: SENSOR_INTERVAL });
    } catch (_) {}
  }
  private async showCriticalNotification(title: string, content: string): Promise<void> {
    try {
      const req: notificationManager.NotificationRequest = {
        id: Date.now() % 99999,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: { title: title, text: content }
        }
      };
      await notificationManager.publish(req);
    } catch (err) {
      console.error('Notification error:', err);
    }
  }
  private async vibratePattern(): Promise<void> {
    try {
      const effect: vibrator.VibrateEffect = { type: 'time', duration: 500 };
      const attr: vibrator.VibrateAttribute = { id: 0, usage: 'unknown' };
      await vibrator.startVibration(effect, attr);
    } catch (err) {
      const e = err as BusinessError;
      console.error(`Vibration error: ${e.code} ${e.message}`);
    }
  }
  private async showEmergencyPopup(): Promise<void> {
    try {
      const req: notificationManager.NotificationRequest = {
        id: Date.now() % 90000,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '⚠ High Heart Rate',
            text: 'Your heart rate suddenly increased. Please check yourself.'
          }
        }
      };
      await notificationManager.publish(req);
    } catch (err) {
      console.error('Emergency Popup Error:', err);
    }
  }
  private async firePopup(): Promise<void> {
    try {
      await this.getUIContext().showAlertDialog({
        title: '⚠ High Heart Rate',
        message: 'Your heart rate is too high. Are you OK?',
        primaryButton: {
          value: 'I am OK',
          action: () => {
            this.showPopup = false;
          }
        },
        secondaryButton: {
          value: 'Need Help',
          action: () => {
            this.showPopup = false;
          }
        }
      });
    } catch (err) {
      const e = err as BusinessError;
      console.error(`showAlertDialog failed: ${e.code} ${e.message}`);
    }
  }
  private updateDailyReports(): void {
    this.reportHRMax = Math.max(this.reportHRMax, this.heartRate);
    this.reportHRMin = Math.min(this.reportHRMin, this.heartRate);
    this.reportHRSum += this.heartRate;
    this.reportHRCount++;
    this.reportTempMax = Math.max(this.reportTempMax, this.temperature);
    this.reportTempMin = Math.min(this.reportTempMin, this.temperature);
    if (this.reportStepStart === 0 && this.steps > 0) {
      this.reportStepStart = this.steps;
    }
    this.reportStepEnd = this.steps;
    const nowT = Date.now();
    if (nowT - this.lastActivityCheck >= 1000) {
      if (this.motionLevel === 'Active' || this.motionLevel === 'Light') {
        this.activeMinutes++;
      }
      else {
        this.restMinutes++;
      }
      this.lastActivityCheck = nowT;
    }
  }
  private updateAdvice(trigger: 'normal' | 'sudden' = 'normal'): void {
    let list: string[] = [];
    if (this.heartRate >= 150 && this.motionLevel === 'Active'){
      list.push('Very high intensity detected. Stop and rest immediately.');
    }
    else if (this.heartRate > 120 && this.motionLevel === 'Active') {
      list.push('High intensity detected. Slow down 1–2 min.');
    }
    else if (this.heartRate > 100 && this.motionLevel !== 'Resting') {
      list.push('Your heart rate is elevated. Watch your pace.');
    }
    else if (this.heartRate < 60 && this.motionLevel === 'Resting') {
      list.push('Very relaxed. A short walk could help.');
    }
    if (this.temperature >= 38.0) {
      list.push('Possible fever. Rest and hydrate.');
    } else if (this.temperature >= 37.5) {
      list.push('Body temperature high. Hydrate.');
    }
    if (this.pressure > 1020) {
      list.push('High pressure. Take a short break.');
    } else if (this.pressure < 990) {
      list.push('Low pressure. Some may feel tired.');
    }
    if (this.steps < 2000 && this.motionLevel === 'Resting') {
      list.push('Low activity today. Try a walk.');
    } else if (this.steps >= 8000 && this.steps < 12000) {
      list.push('Great! 8K steps achieved.');
    } else if (this.steps >= 12000) {
      list.push('Very active day. Good work.');
    }
    if (list.length === 0) {
      list.push('All good. Keep going 👍');
    }
    this.updateDailyReports();
    const now = Date.now();
    const isCritical = (this.heartRate >= 150 && this.motionLevel === 'Active') || (this.temperature >= 38.0);
    const text = list.join('\n');
    if (trigger === 'normal') {
      if (this.lastAdviceTime !== 0 && (now - this.lastAdviceTime) < ADVICE_INTERVAL_MS && !isCritical) {
        this.statusLabel = `HR: ${this.heartRate} bpm • Steps: ${this.steps}`;
        return;
      }
      this.adviceText = text;
      this.lastAdviceTime = now;
    } else {
      this.adviceText = `⚠ Instant alert:\n${text}`;
      this.lastAdviceTime = now;
    }
    this.statusLabel = `HR: ${this.heartRate} bpm • Steps: ${this.steps}`;
    if (isCritical || trigger === 'sudden') {
      this.showPopup = true;
      void this.showCriticalNotification('Health Alert', text);
      void this.vibratePattern();
      void this.showEmergencyPopup();
    }
  }
  private stopSensors(): void {
    this.sensorsActive = false;
    try { sensor.off(sensor.SensorId.ACCELEROMETER); } catch (_) {}
    try { sensor.off(sensor.SensorId.HEART_RATE); } catch (_) {}
    try { sensor.off(sensor.SensorId.PEDOMETER); } catch (_) {}
    try { sensor.off(sensor.SensorId.BAROMETER); } catch (_) {}
    try { sensor.off(sensor.SensorId.AMBIENT_TEMPERATURE); } catch (_) {}
    if (MOCK_MODE) {clearInterval(this.mockTimer);}
    this.statusLabel = 'Sensors Paused';
    this.adviceText = 'Tracking Stopped';
  }
  private resumeSensors(): void {
    this.sensorsActive = true;
    if (MOCK_MODE) {
      clearInterval(this.mockTimer);
      this.startMockValues();
    } else {
      this.startSensors();
    }
    this.statusLabel = 'Live';
  }
  build() {
    Stack() {
      if (this.showStartScreen) {
        StartView({
          sensorsActive: this.sensorsActive,
          onToggle: () => {
            if (this.sensorsActive) {
              this.stopSensors();
              return;
            }
            this.sensorsActive = true;
            if (MOCK_MODE) {
              this.startMockValues();
              this.showStartScreen = false;
              return;
            }
            void this.initPermissions().then(ok => {
              if (ok) {
                this.startSensors();
                this.showStartScreen = false;
              } else {
                this.statusLabel = 'Permission Required';
              }
            });
          },
          onSeeReports: () => {
            this.showStartScreen = false;
            this.showReports = true;
          }
        });
      } else if (this.showReports) {
        ReportsView({
          reportHRMax: this.reportHRMax,
          reportHRMin: this.reportHRMin,
          reportHRSum: this.reportHRSum,
          reportHRCount: this.reportHRCount,
          reportTempMax: this.reportTempMax,
          reportTempMin: this.reportTempMin,
          reportStepStart: this.reportStepStart,
          reportStepEnd: this.reportStepEnd,
          activeMinutes: this.activeMinutes,
          restMinutes: this.restMinutes,
          pressure: this.pressure,
          onBack: () => {
            this.showReports = false;
            this.showStartScreen = true;
          }
        });
      } else {
        DashboardView({
          sensorsActive: this.sensorsActive,
          statusLabel: this.statusLabel,
          adviceText: this.adviceText,
          heartRate: this.heartRate,
          temperature: this.temperature,
          pressure: this.pressure,
          steps: this.steps,
          motionLevel: this.motionLevel,
          onBack: () => {
            this.showStartScreen = true;
            this.showReports = false;
          },onToggle: () => {
            if (this.sensorsActive) {
              this.stopSensors();
            }
            else {
              this.resumeSensors();
            }
          }
        });
      }
    }.width('100%').height('100%');
  }
  @Builder
  private metricCard(label: string, value: number | string, unit: string) {
    Column({ space: 2 }) {
      Text(label).fontSize(12).opacity(0.7);
      Text(value + (unit ? ` ${unit}` : '')).fontSize(16).fontWeight(FontWeight.Medium);
    }.padding(10).backgroundColor('#151B25').borderRadius(16).width('50%');
  }
}
