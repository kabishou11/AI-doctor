@Component
export struct GlobalSettingsModal {
  onClose?: () => void

  build() {
    Column() {
      // Modal overlay
      Column() {
        // Modal content
        Column() {
          // Header
          Row() {
            Text('全局设置')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)

            Button('', { type: ButtonType.Circle, stateEffect: true })
              .width(32)
              .height(32)
              .backgroundColor('rgba(0, 0, 0, 0)')
              .onClick(() => this.onClose?.())
          }
          .width('100%')
          .height(50)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .borderBottomColor('#f0f0f0')
          .borderBottomWidth(1)

          // Tabs placeholder
          Tabs({ barPosition: BarPosition.Start }) {
            TabContent() {
              Column() {
                Text('全局系统提示词')
                  .fontSize(14)
                  .margin({ top: 12, left: 12 })

                TextArea({ placeholder: '在此输入系统提示词...' })
                  .width('100%')
                  .height(200)
                  .margin({ top: 12, left: 12, right: 12 })
                  .padding(12)
              }
              .width('100%')
              .padding(12)
            }
            .tabBar('基本设置')

            TabContent() {
              Column() {
                Text('高级选项')
                  .fontSize(14)
                  .margin({ top: 12, left: 12 })
              }
              .width('100%')
              .padding(12)
            }
            .tabBar('高级设置')
          }
          .width('100%')
          .height(300)
          .barHeight(40)

          // Footer buttons
          Row() {
            Button('取消', { type: ButtonType.Normal, stateEffect: true })
              .layoutWeight(1)
              .onClick(() => this.onClose?.())

            Button('保存', { type: ButtonType.Normal, stateEffect: true })
              .layoutWeight(1)
              .backgroundColor('#1890ff')
              .margin({ left: 8 })
              .onClick(() => this.onClose?.())
          }
          .width('100%')
          .height(50)
          .padding({ left: 16, right: 16, bottom: 16 })
          .gap(8)
        }
        .width('90%')
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.45)')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }
}
