@Component
export struct Header {
  onOpenSessions?: () => void
  onOpenGlobalSettings?: () => void
  onOpenConsultationSettings?: () => void

  build() {
    Row() {
      // Left side: Logo and title
      Row() {
        Image($r('app.media.logo'))
          .width(28)
          .height(28)

        Text('AI 医疗会诊面板')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })

        Text('【本内容仅供参考，身体不适尽早就医】')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ff4d4f')
          .margin({ left: 8 })
      }
      .gap(8)
      .alignItems(VerticalAlign.Center)

      Blank()

      // Right side: Action buttons
      Row() {
        Button('问诊列表', { type: ButtonType.Normal, stateEffect: true })
          .onClick(() => this.onOpenSessions?.())

        Button('全局设置', { type: ButtonType.Normal, stateEffect: true })
          .onClick(() => this.onOpenGlobalSettings?.())

        Button('问诊设置', { type: ButtonType.Capsule, stateEffect: true })
          .backgroundColor('#1890ff')
          .onClick(() => this.onOpenConsultationSettings?.())
      }
      .gap(8)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#ffffff')
    .borderBottomColor('#f0f0f0')
    .borderBottomWidth(1)
  }
}
