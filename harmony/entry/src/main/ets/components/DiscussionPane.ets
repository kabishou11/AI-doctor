@Component
export struct DiscussionPane {
  build() {
    Column() {
      // Header for discussion pane
      Row() {
        Text('医生讨论')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .borderBottomColor('#f0f0f0')
      .borderBottomWidth(1)

      // Discussion content area
      Scroll() {
        Column() {
          // Placeholder content for discussion messages
          Text('欢迎来到医疗会诊系统')
            .fontSize(14)
            .fontColor('#8c8c8c')
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(100)
            .justifyContent(FlexAlign.Center)

          // Additional placeholder items
          ForEach([1, 2, 3], () => {
            Column() {
              Text('医生发言内容')
                .fontSize(13)
                .lineHeight(1.5)
            }
            .width('100%')
            .padding(12)
            .margin({ top: 8 })
            .backgroundColor('#f5f5f5')
            .borderRadius(4)
          })
        }
        .width('100%')
        .padding(12)
        .gap(8)
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)

      // Input area
      Row() {
        TextInput({ placeholder: '输入问诊内容...' })
          .width('100%')
          .height(40)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)

        Button('发送', { type: ButtonType.Normal, stateEffect: true })
          .backgroundColor('#1890ff')
          .width(80)
          .height(40)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(60)
      .padding(12)
      .gap(8)
      .alignItems(VerticalAlign.Center)
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
