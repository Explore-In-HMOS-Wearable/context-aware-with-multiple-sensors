export interface ReportsViewParams {
  reportHRMax: number;
  reportHRMin: number;
  reportHRSum: number;
  reportHRCount: number;

  reportTempMax: number;
  reportTempMin: number;

  reportStepStart: number;
  reportStepEnd: number;

  activeMinutes: number;
  restMinutes: number;

  pressure: number;

  onBack: () => void;
}

@Builder
export function ReportsView(p: ReportsViewParams) {
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
            Text('Max').fontSize(12).opacity(0.7)
            Text(`${p.reportHRMax} bpm`)
              .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Red)
          }
          .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')

          Column() {
            Text('Min').fontSize(12).opacity(0.7)
            Text(`${p.reportHRMin} bpm`)
              .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Pink)
          }
          .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')
        }

        Column() {
          Text('Average').fontSize(12).opacity(0.7)
          Text(`${(p.reportHRSum / p.reportHRCount || 0).toFixed(1)} bpm`)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.White)
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
            Text('Max').fontSize(12).opacity(0.7)
            Text(`${p.reportTempMax.toFixed(1)} °C`)
              .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Yellow)
          }
          .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')

          Column() {
            Text('Min').fontSize(12).opacity(0.7)
            Text(`${p.reportTempMin.toFixed(1)} °C`)
              .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFE0A3')
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
          Text('Steps Today').fontSize(12).opacity(0.7)
          Text(`${p.reportStepEnd - p.reportStepStart} steps`)
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
            Text('Active Time').fontSize(12).opacity(0.7)
            Text(`${Math.floor(p.activeMinutes / 60)} min`)
              .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Yellow)
          }
          .padding(10).backgroundColor('#1B1F29').borderRadius(12).width('50%')

          Column() {
            Text('Rest Time').fontSize(12).opacity(0.7)
            Text(`${Math.floor(p.restMinutes / 60)} min`)
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
          Text('Current Pressure').fontSize(12).opacity(0.7)
          Text(`${p.pressure.toFixed(0)} hPa`)
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
    .margin({ top: 0 })

    Button('Back')
      .width('60%')
      .height(36)
      .margin({ top: 18 })
      .backgroundColor(Color.Green)
      .fontWeight(FontWeight.Bold)
      .onClick(() => {
        p.onBack();
      })
  }
  .padding(12)
}
