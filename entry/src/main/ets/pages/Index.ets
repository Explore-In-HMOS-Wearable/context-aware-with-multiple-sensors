import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Permissions } from '@kit.AbilityKit';
import PermissionHelper from '../common/PermissionHelper';
import { notificationManager } from '@kit.NotificationKit';
import vibrator from '@ohos.vibrator';

const SENSOR_INTERVAL = 200_000_000; // 200 ms
const MOCK_MODE = true; // For mock values
const ADVICE_INTERVAL_MS = 60000; // For advice interval, can be changed to decided time.

@Entry
@Component
struct Index {

  @State sensorsActive: boolean = false;

  // Start Screen and Report Screen
  @State showStartScreen: boolean = true;
  @State showReports: boolean = false;

  // Raw sensor values
  @State heartRate: number = 0;
  @State temperature: number = 0;
  @State pressure: number = 0;
  @State steps: number = 0;
  @State motionLevel: string = 'Unknown';
  @State showPopup: boolean = false;

  // Suggestions
  @State statusLabel: string = 'Initializing...';
  @State adviceText: string = 'Sensors are starting, please wait.';

  // For lightweight daily reports
  @State reportHRMax: number = 0;
  @State reportHRMin: number = 999;
  private reportHRSum: number = 0;
  private reportHRCount: number = 0;

  private reportStepStart: number = 0;
  private reportStepEnd: number = 0;

  @State reportTempMax: number = 0;
  @State reportTempMin: number = 100; // todo

  @State activeMinutes: number = 0;
  @State restMinutes: number = 0;

  private lastActivityCheck: number = Date.now();

  // Mock
  private lastAdviceTime: number = 0;
  private mockTimer: number = 0; // For mock

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

    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
    }
    catch(_) {

    }
    try {
      sensor.off(sensor.SensorId.HEART_RATE);
    }
    catch(_) {

    }
    try {
      sensor.off(sensor.SensorId.PEDOMETER);
    }
    catch(_) {

    }
    try {
      sensor.off(sensor.SensorId.BAROMETER);
    }
    catch(_) {

    }
    try {
      sensor.off(sensor.SensorId.AMBIENT_TEMPERATURE);
    }
    catch(_) {

    }
  }

  // -------------------- MOCK SENSOR --------------------
  private startMockValues(): void {
    this.mockTimer = setInterval(() => {
      this.heartRate = 60 + Math.floor(Math.random()*80);
      this.temperature = 36 + Math.random() * 2;;
      this.pressure = 1000 + Math.random()*20;
      this.steps += Math.floor(Math.random()*20);
      this.motionLevel = ['Resting','Light','Active'][Math.floor(Math.random()*3)];

      this.updateAdvice();
    }, 600);
  }

  // -------------------- PERMISSION --------------------
  private async initPermissions(): Promise<boolean> {
    const perms: Array<Permissions> = [
      'ohos.permission.ACCELEROMETER',
      'ohos.permission.ACTIVITY_MOTION',
      'ohos.permission.READ_HEALTH_DATA'
    ];
    return await PermissionHelper.requestPermissions(perms);
  }

  // -------------------- REAL SENSOR --------------------
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
        }
        else if (m < 1.4 * 9.81) {
          this.motionLevel = 'Light';
        }
        else {
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

  // -------------------- NOTIFICATION + VIBRATION --------------------
  private async showCriticalNotification(title: string, content: string): Promise<void> {
    try {
      const req: notificationManager.NotificationRequest = {
        id: Date.now() % 99999,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content
          }
        }
      };
      await notificationManager.publish(req);
    } catch (err) {
      console.error('Notification error:', err);
    }
  }

  private async vibratePattern(): Promise<void> {
    try {
      const effect: vibrator.VibrateEffect = {
        type: 'time',
        duration: 500
      };

      const attr: vibrator.VibrateAttribute = {
        id: 0,
        usage: 'unknown'
      };

      await vibrator.startVibration(effect, attr);
    }
    catch (err) {
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
    }
    catch (err) {
      console.error('Emergency Popup Error:', err);
    }
  }


  private firePopup(): void {
    setTimeout(() => {
      AlertDialog.show({
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
    }, 50);
  }

  // Report Function
  private updateDailyReports(): void {
    // HR Rate Report
    this.reportHRMax = Math.max(this.reportHRMax, this.heartRate);
    this.reportHRMin = Math.min(this.reportHRMin, this.heartRate);
    this.reportHRSum += this.heartRate;
    this.reportHRCount++;

    // Temperature Report
    this.reportTempMax = Math.max(this.reportTempMax, this.temperature);
    this.reportTempMin = Math.min(this.reportTempMin, this.temperature);

    // Steps Report
    if(this.reportStepStart === 0 && this.steps > 0) {
      this.reportStepStart = this.steps;
    }
    this.reportStepEnd = this.steps;

    // Activity Time
    const nowT = Date.now();
    if(nowT - this.lastActivityCheck >= 1000) { // Per second
      if(this.motionLevel === 'Active' || this.motionLevel === 'Light'){
        this.activeMinutes++;
      }
      else {
        this.restMinutes++;
      }
      this.lastActivityCheck = nowT;
    }

  }


  //  SUGGESTION ENGINE
  private updateAdvice(trigger: 'normal' | 'sudden' = 'normal'): void {
    let list: string[] = [];

    // HR rules
    if (this.heartRate >= 150 && this.motionLevel === 'Active') {
      list.push('Very high intensity detected. Stop and rest immediately.');
    } else if (this.heartRate > 120 && this.motionLevel === 'Active') {
      list.push('High intensity detected. Slow down 1–2 min.');
    } else if (this.heartRate > 100 && this.motionLevel !== 'Resting') {
      list.push('Your heart rate is elevated. Watch your pace.');
    } else if (this.heartRate < 60 && this.motionLevel === 'Resting') {
      list.push('Very relaxed. A short walk could help.');
    }

    // Temperature rules
    if (this.temperature >= 38.0) {
      list.push('Possible fever. Rest and hydrate.');
    } else if (this.temperature >= 37.5) {
      list.push('Body temperature high. Hydrate.');
    }

    // Pressure rules
    if (this.pressure > 1020) {
      list.push('High pressure. Take a short break.');
    } else if (this.pressure < 990) {
      list.push('Low pressure. Some may feel tired.');
    }

    // Steps rules
    if (this.steps < 2000 && this.motionLevel === 'Resting') {
      list.push('Low activity today. Try a walk.');
    } else if (this.steps >= 8000 && this.steps < 12000) {
      list.push('Great! 8K steps achieved.');
    } else if (this.steps >= 12000) {
      list.push('Very active day. Good work.');
    }


    if (list.length === 0) list.push('All good. Keep going 👍');

    this.updateDailyReports();

    const now = Date.now();
    const isCritical =
      (this.heartRate >= 150 && this.motionLevel === 'Active') ||
        (this.temperature >= 38.0);

    const text = list.join('\n');

    if (trigger === 'normal') {
      if (this.lastAdviceTime !== 0 && (now - this.lastAdviceTime) < ADVICE_INTERVAL_MS && !isCritical) {
        this.statusLabel = `HR: ${this.heartRate} bpm • Steps: ${this.steps}`;
        return;
      }
      this.adviceText = text;
      this.lastAdviceTime = now;
    } else {
      this.adviceText = '⚠ Instant alert:\n' + text;
      this.lastAdviceTime = now;
    }

    this.statusLabel = `HR: ${this.heartRate} bpm • Steps: ${this.steps}`;

    // Critical? Notify + vibrate
    if (isCritical || trigger === 'sudden') {
      this.showPopup = true;
      void this.showCriticalNotification('Health Alert', text);
      void this.vibratePattern();
      void this.showEmergencyPopup();
    }
  }

  // Start and Stop Sensors
  private stopSensors(): void {
    this.sensorsActive = false;

    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
    }
    catch(_) {

    }
    try {
      sensor.off(sensor.SensorId.HEART_RATE);
    }
    catch(_) {

    }

    try {
      sensor.off(sensor.SensorId.PEDOMETER);
    }
    catch(_) {

    }

    try {
      sensor.off(sensor.SensorId.BAROMETER);
    }
    catch(_) {

    }

    try {
      sensor.off(sensor.SensorId.AMBIENT_TEMPERATURE);
    }
    catch(_) {

    }

    if(MOCK_MODE) {
      clearInterval(this.mockTimer);
    }
    this.statusLabel = 'Sensors Paused';
    this.adviceText = 'Tracking Stopped';
  }

  private resumeSensors(): void {
    this.sensorsActive = true;

    if(MOCK_MODE) {
      clearInterval(this.mockTimer);
      this.startMockValues();
    }
    else{
      this.startSensors();
    }
    this.statusLabel = 'Live';
  }


  // UI
  build() {
    if(this.showStartScreen) {
      Column() {
        Text('Aware\nCoach')
          .fontSize(22)
          .fontWeight(FontWeight.Bolder)
          .fontColor(Color.Green)
          .margin({ top: 17 })
          .textAlign(TextAlign.Center)
          .width('100%')

        Text('WELCOME!')
          .fontSize(18)
          .fontColor(Color.Gray)
          .margin({ top: 10 })

        Text('Enable sensors to start monitoring your health.')
          .fontSize(14)
          .fontColor(Color.Red)
          .textAlign(TextAlign.Center)
          .margin({ top: 12 })
          .width('80%')

        Button(this.sensorsActive ? 'Stop' : 'Enable')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(Color.Green)
          .fontColor(Color.Black)
          .width('60%')
          .height(40)
          .margin({ top: 12 })
          .onClick(() => {

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
          })

        Button('See Reports')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#333333')
          .fontColor(Color.White)
          .width('60%')
          .height(36)
          .margin({top: 8})
          .onClick(() => {
            this.showStartScreen = false;
            this.showReports = true;
          })
      }
      .padding({top: -10})
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#05060A')
    }
    else if (this.showReports) {
      Column() {
        Text('Daily Reports')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 10, bottom: 10 })

        Swiper() {
          // -------- CARD 1: HEART RATE --------
          Column({ space: 8 }) {
            Text('Heart Rate')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .width('75%')

            Row({ space: 10 }) {
              Column() {
                Text('Max')
                  .fontSize(12).opacity(0.7)
                Text(`${this.reportHRMax} bpm`)
                  .fontSize(22).fontWeight(FontWeight.Bold)
                  .fontColor(Color.Red)
              }
              .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')

              Column() {
                Text('Min')
                  .fontSize(12).opacity(0.7)
                Text(`${this.reportHRMin} bpm`)
                  .fontSize(22).fontWeight(FontWeight.Bold)
                  .fontColor(Color.Pink)
              }
              .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')
            }

            Column() {
              Text('Average')
                .fontSize(12).opacity(0.7)
              Text(`${(this.reportHRSum / this.reportHRCount || 0).toFixed(1)} bpm`)
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('100%')
          }
          .padding(16)
          .backgroundColor('#101218')
          .borderRadius(20)

          // -------- CARD 2: TEMPERATURE --------
          Column({ space: 10 }) {
            Text('Temperature')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .width('100%')

            Row({ space: 10 }) {
              Column() {
                Text('Max')
                  .fontSize(12).opacity(0.7)
                Text(`${this.reportTempMax.toFixed(1)} °C`)
                  .fontSize(22).fontWeight(FontWeight.Bold)
                  .fontColor(Color.Yellow)
              }
              .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')

              Column() {
                Text('Min')
                  .fontSize(12).opacity(0.7)
                Text(`${this.reportTempMin.toFixed(1)} °C`)
                  .fontSize(22).fontWeight(FontWeight.Bold)
                  .fontColor('#FFE0A3')
              }
              .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')
            }
          }
          .padding(16)
          .backgroundColor('#101218')
          .borderRadius(20)


          // -------- CARD 3: STEPS --------
          Column({ space: 10 }) {
            Text('Steps Summary')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .width('100%')

            Column() {
              Text('Steps Today')
                .fontSize(12).opacity(0.7)
              Text(`${this.reportStepEnd - this.reportStepStart} steps`)
                .fontSize(26).fontWeight(FontWeight.Bold).fontColor(Color.Green)
            }
            .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('100%')
          }
          .padding(16)
          .backgroundColor('#101218')
          .borderRadius(20)

          // -------- CARD 4: ACTIVITY --------
          Column({ space: 10 }) {
            Text('Activity Summary')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .width('100%')

            Row({ space: 10 }) {
              Column() {
                Text('Active Time')
                  .fontSize(12).opacity(0.7)
                Text(`${Math.floor(this.activeMinutes/60)} min`)
                  .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Yellow)
              }
              .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')

              Column() {
                Text('Rest Time')
                  .fontSize(12).opacity(0.7)
                Text(`${Math.floor(this.restMinutes/60)} min`)
                  .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Blue)
              }
              .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')
            }
          }
          .padding(16)
          .backgroundColor('#101218')
          .borderRadius(20)

          // -------- CARD 5: PRESSURE --------
          Column({ space: 10 }) {
            Text('Pressure')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .width('100%')

            Column() {
              Text('Current Pressure')
                .fontSize(12).opacity(0.7)
              Text(`${this.pressure.toFixed(0)} hPa`)
                .fontSize(26).fontWeight(FontWeight.Bold).fontColor(Color.Blue)
            }
            .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('100%')
          }
          .padding(16)
          .backgroundColor('#101218')
          .borderRadius(20)

        }
        .indicator(false)
        .loop(false)
        .itemSpace(12)
        .height('60%')
        .margin({top: 0})

        Button('Back')
          .width('60%')
          .height(36)
          .margin({ top: 18 })
          .backgroundColor(Color.Green)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.showReports = false;
            this.showStartScreen = true;
          })
      }
      .padding(12)
    }
    else {
      Scroll() {
        Column({ space: 10 }) {
          Row({space: 10}) {
            Button('Back')
              .width('40%')
              .height(34)
              .backgroundColor('#333333')
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .onClick(() => {
                this.showStartScreen = true;
                this.showReports = false;
              })

            Button(this.sensorsActive ? 'Stop' : 'Resume')
              .width('40%')
              .height(34)
              .backgroundColor(this.sensorsActive ? '#660000' : '#006600')
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .onClick(() => {
                if(this.sensorsActive) {
                  this.stopSensors();
                }
                else {
                  this.resumeSensors();
                }
              })
          }

          Text('Context Aware Coach')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 12, bottom: 4 });

          Text(this.statusLabel)
            .fontSize(12)
            .opacity(0.8)
            .textAlign(TextAlign.Center)
            .width('100%');

          Row({ space: 6 }) {
            // HEART BOX
            Column() {
              Text('Heart')
                .fontSize(12)
                .opacity(0.7)

              Text(`${this.heartRate} bpm`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Red)
            }
            .padding(10)
            .backgroundColor('#151B25')
            .borderRadius(12)
            .width('50%')

            // TEMP BOX
            Column() {
              Text('Temp')
                .fontSize(12)
                .opacity(0.7)

              Text(`${this.temperature.toFixed(1)} °C`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Yellow)
            }
            .padding(10)
            .backgroundColor('#151B25')
            .borderRadius(12)
            .width('50%')
          }

          Row({ space: 6 }) {

            // PRESSURE BOX
            Column() {
              Text('Pressure')
                .fontSize(12)
                .opacity(0.7)

              Text(`${this.pressure.toFixed(0)} hPa`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Blue)
            }
            .padding(10)
            .backgroundColor('#151B25')
            .borderRadius(12)
            .width('50%')

            // STEPS BOX
            Column() {
              Text('Steps')
                .fontSize(12)
                .opacity(0.7)

              Text(`${this.steps}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Green)
            }
            .padding(10)
            .backgroundColor('#151B25')
            .borderRadius(12)
            .width('50%')
          }

          Row({ space: 6 }) {

            //
            Column() {
              Text('Motion')
                .fontSize(12)
                .opacity(0.7)

              Text(`${this.motionLevel}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Orange)
            }
            .padding(10)
            .backgroundColor('#151B25')
            .borderRadius(12)
            .width('100%')
          }

          // ---------- SUGGESTION ----------
          Column() {
            Text('Suggestion')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Red)

            Text(this.adviceText)
              .fontSize(14)
              .fontColor(Color.White)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .padding(10)
          .backgroundColor('#262A33')
          .borderRadius(16)
          .width('100%')
          .margin({ top: 10 })
        }
        .padding(12)
      }

    }


  }

  @Builder
  private metricCard(label: string, value: number | string, unit: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(12)
        .opacity(0.7);

      Text(value + (unit ? ` ${unit}` : ''))
        .fontSize(16)
        .fontWeight(FontWeight.Medium);
    }
    .padding(10)
    .backgroundColor('#151B25')
    .borderRadius(16)
    .width('50%');
  }
}