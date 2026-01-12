export interface DashboardViewParams {
  sensorsActive: boolean;

  heartRate: number;
  temperature: number;
  pressure: number;
  steps: number;
  motionLevel: string;

  statusLabel: string;
  adviceText: string;

  onBack: () => void;
  onToggle: () => void;
}

@Builder
export function DashboardView(p: DashboardViewParams) {
  Scroll() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Button('Back')
          .width('40%')
          .height(34)
          .backgroundColor('#333333')
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            p.onBack();
          })

        Button(p.sensorsActive ? 'Stop' : 'Resume')
          .width('40%')
          .height(34)
          .backgroundColor(p.sensorsActive ? '#660000' : '#006600')
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            p.onToggle();
          })
      }

      Text('Context Aware Coach')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 12, bottom: 4 });

      Text(p.statusLabel)
        .fontSize(12)
        .opacity(0.8)
        .textAlign(TextAlign.Center)
        .width('100%');

      Row({ space: 6 }) {
        Column() {
          Text('Heart').fontSize(12).opacity(0.7)
          Text(`${p.heartRate} bpm`)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Red)
        }
        .padding(10).backgroundColor('#151B25').borderRadius(12).width('50%')

        Column() {
          Text('Temp').fontSize(12).opacity(0.7)
          Text(`${p.temperature.toFixed(1)} °C`)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Yellow)
        }
        .padding(10).backgroundColor('#151B25').borderRadius(12).width('50%')
      }

      Row({ space: 6 }) {
        Column() {
          Text('Pressure').fontSize(12).opacity(0.7)
          Text(`${p.pressure.toFixed(0)} hPa`)
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.Blue)
        }
        .padding(10).backgroundColor('#151B25').borderRadius(12).width('50%')

        Column() {
          Text('Steps').fontSize(12).opacity(0.7)
          Text(`${p.steps}`)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Green)
        }
        .padding(10).backgroundColor('#151B25').borderRadius(12).width('50%')
      }

      Row({ space: 6 }) {
        Column() {
          Text('Motion').fontSize(12).opacity(0.7)
          Text(`${p.motionLevel}`)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.Orange)
        }
        .padding(10).backgroundColor('#151B25').borderRadius(12).width('100%')
      }

      Column() {
        Text('Suggestion').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.Red)
        Text(p.adviceText)
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
