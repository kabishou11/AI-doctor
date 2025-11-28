@Component
export struct SessionListDrawer {
  onClose?: () => void

  build() {
    Column() {
      // Drawer overlay
      Row() {
        // Drawer content
        Column() {
          // Header
          Row() {
            Text('问诊列表')
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

          // Sessions list
          Scroll() {
            Column() {
              // New session button
              Button('+ 新建问诊', { type: ButtonType.Normal, stateEffect: true })
                .width('100%')
                .margin({ bottom: 12 })
                .backgroundColor('#1890ff')

              // Placeholder session items
              ForEach([1, 2, 3, 4, 5], (index: number) => {
                Column() {
                  Row() {
                    Column() {
                      Text(`问诊 ${index}`)
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)

                      Text('患者：未设置')
                        .fontSize(12)
                        .fontColor('#8c8c8c')
                        .margin({ top: 4 })

                      Text('创建于：2025-01-15')
                        .fontSize(12)
                        .fontColor('#8c8c8c')
                        .margin({ top: 2 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Row() {
                      Button('查看', { type: ButtonType.Normal, stateEffect: true })
                        .fontSize(12)

                      Button('导出', { type: ButtonType.Normal, stateEffect: true })
                        .fontSize(12)
                        .margin({ left: 4 })

                      Button('删除', { type: ButtonType.Normal, stateEffect: true })
                        .fontSize(12)
                        .fontColor('#ff4d4f')
                        .margin({ left: 4 })
                    }
                    .gap(2)
                  }
                  .width('100%')
                  .padding(12)
                  .justifyContent(FlexAlign.SpaceBetween)
                  .alignItems(VerticalAlign.Top)
                }
                .width('100%')
                .padding(0)
                .margin({ bottom: 12 })
                .backgroundColor('#f5f5f5')
                .borderRadius(4)
              })
            }
            .width('100%')
            .padding(12)
          }
          .layoutWeight(1)
          .scrollable(ScrollDirection.Vertical)
        }
        .width('80%')
        .height('100%')
        .backgroundColor('#ffffff')
        .alignItems(VerticalAlign.Top)

        // Drawer overlay (clickable area outside drawer)
        Column()
          .width('20%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.45)')
          .onClick(() => this.onClose?.())
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }
}
