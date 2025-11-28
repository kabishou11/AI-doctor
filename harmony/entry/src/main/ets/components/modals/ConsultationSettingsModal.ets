@Component
export struct ConsultationSettingsModal {
  onClose?: () => void

  build() {
    Column() {
      // Modal overlay
      Column() {
        // Modal content
        Column() {
          // Header
          Row() {
            Text('问诊设置')
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
              Scroll() {
                Column() {
                  Text('医生配置')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 12 })

                  Button('+ 添加医生', { type: ButtonType.Normal, stateEffect: true })
                    .width('100%')
                    .margin({ top: 12 })

                  // Placeholder doctor list
                  ForEach([1, 2], () => {
                    Row() {
                      Column() {
                        Text('医生名称')
                          .fontSize(14)
                          .fontWeight(FontWeight.Bold)

                        Text('GPT-4')
                          .fontSize(12)
                          .fontColor('#8c8c8c')
                          .margin({ top: 4 })
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      Row() {
                        Button('编辑', { type: ButtonType.Normal, stateEffect: true })
                          .fontSize(12)

                        Button('删除', { type: ButtonType.Normal, stateEffect: true })
                          .fontSize(12)
                          .margin({ left: 4 })
                      }
                      .gap(4)
                    }
                    .width('100%')
                    .padding(12)
                    .margin({ top: 8 })
                    .backgroundColor('#f5f5f5')
                    .borderRadius(4)
                    .justifyContent(FlexAlign.SpaceBetween)
                    .alignItems(VerticalAlign.Center)
                  })
                }
                .width('100%')
                .padding(12)
              }
              .layoutWeight(1)
              .scrollable(ScrollDirection.Vertical)
            }
            .tabBar('医生配置')

            TabContent() {
              Scroll() {
                Column() {
                  Text('参与医生')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 12 })

                  ForEach([1, 2, 3], () => {
                    Row() {
                      Checkbox()
                        .width(20)
                        .height(20)
                        .margin({ right: 8 })

                      Text('医生名称')
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .padding(12)
                    .margin({ top: 8 })
                    .backgroundColor('#f5f5f5')
                    .borderRadius(4)
                    .alignItems(VerticalAlign.Center)
                  })
                }
                .width('100%')
                .padding(12)
              }
              .layoutWeight(1)
              .scrollable(ScrollDirection.Vertical)
            }
            .tabBar('参与医生')
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
