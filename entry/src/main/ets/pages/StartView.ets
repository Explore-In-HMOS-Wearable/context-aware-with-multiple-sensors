export interface StartViewParams {
  sensorsActive: boolean;
  onToggle: () => void;
  onSeeReports: () => void;
}

@Builder
export function StartView(p: StartViewParams) {
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

    Button(p.sensorsActive ? 'Stop' : 'Enable')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .backgroundColor(Color.Green)
      .fontColor(Color.Black)
      .width('60%')
      .height(40)
      .margin({ top: 12 })
      .onClick(() => {
        p.onToggle();
      })

    Button('See Reports')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .backgroundColor('#333333')
      .fontColor(Color.White)
      .width('60%')
      .height(36)
      .margin({ top: 8 })
      .onClick(() => {
        p.onSeeReports();
      })
  }
  .padding({ top: -10 })
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
  .backgroundColor('#05060A')
}
