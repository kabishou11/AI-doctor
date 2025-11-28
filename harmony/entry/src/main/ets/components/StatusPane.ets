@Component
export struct StatusPane {
  onOpenSettings?: () => void

  build() {
    Column() {
      // Header for status pane
      Row() {
        Text('会诊状态')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .borderBottomColor('#f0f0f0')
      .borderBottomWidth(1)

      // Status content area
      Scroll() {
        Column() {
          // Status information sections
          Column() {
            Text('患者信息')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .width('100%')

            Row() {
              Text('姓名：')
                .width('40%')
              Text('未设置')
                .layoutWeight(1)
                .fontColor('#8c8c8c')
            }
            .width('100%')
            .margin({ top: 8 })

            Row() {
              Text('年龄：')
                .width('40%')
              Text('未设置')
                .layoutWeight(1)
                .fontColor('#8c8c8c')
            }
            .width('100%')
            .margin({ top: 4 })

            Row() {
              Text('症状：')
                .width('40%')
              Text('未设置')
                .layoutWeight(1)
                .fontColor('#8c8c8c')
            }
            .width('100%')
            .margin({ top: 4 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#f5f5f5')
          .borderRadius(4)
          .margin({ bottom: 12 })

          // Doctors status
          Column() {
            Text('参与医生')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .margin({ bottom: 8 })

            Column() {
              Row() {
                Circle()
                  .width(8)
                  .height(8)
                  .fill('#1890ff')

                Text('医生 1')
                  .margin({ left: 8 })
                  .layoutWeight(1)

                Text('正在思考...')
                  .fontSize(12)
                  .fontColor('#8c8c8c')
              }
              .width('100%')
              .height(32)
              .alignItems(VerticalAlign.Center)

              Row() {
                Circle()
                  .width(8)
                  .height(8)
                  .fill('#95de64')

                Text('医生 2')
                  .margin({ left: 8 })
                  .layoutWeight(1)

                Text('已回复')
                  .fontSize(12)
                  .fontColor('#8c8c8c')
              }
              .width('100%')
              .height(32)
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .gap(8)
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#f5f5f5')
          .borderRadius(4)
        }
        .width('100%')
        .padding(12)
        .gap(8)
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)

      // Action buttons
      Column() {
        Button('开始会诊', { type: ButtonType.Normal, stateEffect: true })
          .width('100%')
          .backgroundColor('#1890ff')
          .margin({ bottom: 8 })

        Button('问诊设置', { type: ButtonType.Normal, stateEffect: true })
          .width('100%')
          .backgroundColor('#1890ff')
          .onClick(() => this.onOpenSettings?.())
      }
      .width('100%')
      .padding(12)
      .gap(8)
      .backgroundColor('#fafafa')
      .borderTopColor('#f0f0f0')
      .borderTopWidth(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
    .borderRadius(4)
    .border({
      width: 1,
      color: '#f0f0f0',
      radius: 4
    })
  }
}
