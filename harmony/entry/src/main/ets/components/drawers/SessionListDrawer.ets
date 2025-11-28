import { getAppContext } from '../../common/AppContext'
import { FileUtils } from '../../common/utils/FileUtils'
import { Logger } from '../../common/utils/Logger'

const TAG = 'SessionListDrawer'

@Component
export struct SessionListDrawer {
  @State sessions: any[] = []
  @State currentSessionId: string = ''
  @State isLoading: boolean = false
  @State renaming: string | null = null
  @State renameValue: string = ''
  @State exporting: boolean = false

  onClose?: () => void

  aboutToAppear() {
    this.loadSessions()
  }

  loadSessions() {
    try {
      const appCtx = getAppContext()
      if (!appCtx.isInitialized()) {
        Logger.warn(TAG, 'AppContext not initialized')
        return
      }

      const repository = appCtx.getSessions()
      this.sessions = repository.getSessions()
      this.currentSessionId = repository.currentId
    } catch (e) {
      Logger.error(TAG, `Failed to load sessions: ${e}`)
    }
  }

  onCreate() {
    try {
      const appCtx = getAppContext()
      const repository = appCtx.getSessions()
      this.isLoading = true
      
      repository.createNew('新建问诊').then((id) => {
        repository.switchTo(id).then(() => {
          appCtx.switchSession(id).then(() => {
            this.loadSessions()
            this.isLoading = false
          }).catch((e) => {
            Logger.error(TAG, `Failed to switch session: ${e}`)
            this.isLoading = false
          })
        }).catch((e) => {
          Logger.error(TAG, `Failed to switch to new session: ${e}`)
          this.isLoading = false
        })
      }).catch((e) => {
        Logger.error(TAG, `Failed to create session: ${e}`)
        this.isLoading = false
      })
    } catch (e) {
      Logger.error(TAG, `Create session error: ${e}`)
      this.isLoading = false
    }
  }

  onOpen(id: string) {
    try {
      const appCtx = getAppContext()
      appCtx.switchSession(id).then(() => {
        this.loadSessions()
      }).catch((e) => {
        Logger.error(TAG, `Failed to open session: ${e}`)
      })
    } catch (e) {
      Logger.error(TAG, `Open session error: ${e}`)
    }
  }

  onRenameStart(id: string, currentName: string) {
    this.renaming = id
    this.renameValue = currentName
  }

  onRenameSave(id: string) {
    if (!this.renameValue || !this.renameValue.trim()) {
      Logger.warn(TAG, 'Empty name not allowed')
      return
    }

    try {
      const appCtx = getAppContext()
      const repository = appCtx.getSessions()
      repository.rename(id, this.renameValue.trim()).then(() => {
        this.loadSessions()
        this.renaming = null
        this.renameValue = ''
      }).catch((e) => {
        Logger.error(TAG, `Failed to rename session: ${e}`)
      })
    } catch (e) {
      Logger.error(TAG, `Rename error: ${e}`)
    }
  }

  onRenameCancel() {
    this.renaming = null
    this.renameValue = ''
  }

  onDelete(id: string) {
    try {
      const appCtx = getAppContext()
      const repository = appCtx.getSessions()
      repository.remove(id).then(() => {
        this.loadSessions()
      }).catch((e) => {
        Logger.error(TAG, `Failed to delete session: ${e}`)
      })
    } catch (e) {
      Logger.error(TAG, `Delete error: ${e}`)
    }
  }

  async onExportJSON(id: string, sessionName: string) {
    try {
      this.exporting = true
      const appCtx = getAppContext()
      const repository = appCtx.getSessions()
      const jsonStr = await repository.exportJSON(id)

      if (!jsonStr) {
        Logger.warn(TAG, 'Session data not found')
        this.exporting = false
        return
      }

      const fileName = FileUtils.formatFileName(sessionName, 'json')
      await FileUtils.exportJSON(fileName, jsonStr)
      Logger.info(TAG, `Session exported as ${fileName}`)
      this.exporting = false
    } catch (e) {
      Logger.error(TAG, `Export error: ${e}`)
      this.exporting = false
    }
  }

  formatDateTime(dateStr: string): string {
    try {
      const date = new Date(dateStr)
      if (isNaN(date.getTime())) {
        return dateStr || '未知时间'
      }
      const pad = (n: number) => String(n).padStart(2, '0')
      return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`
    } catch (e) {
      return dateStr || '未知时间'
    }
  }

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

          // Action buttons
          Row() {
            Button('+ 新建问诊', { type: ButtonType.Normal, stateEffect: true })
              .layoutWeight(1)
              .backgroundColor('#1890ff')
              .fontColor('#ffffff')
              .onClick(() => this.onCreate())
              .enabled(!this.isLoading)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .gap(8)

          // Sessions list
          Scroll() {
            Column() {
              if (this.sessions.length === 0) {
                Text('暂无问诊')
                  .fontSize(14)
                  .fontColor('#8c8c8c')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .margin({ top: 24 })
              } else {
                ForEach(this.sessions, (session: any) => {
                  if (this.renaming === session.id) {
                    // Rename mode
                    Row() {
                      TextInput({ placeholder: '输入新名称', text: this.renameValue })
                        .layoutWeight(1)
                        .onChange((value) => {
                          this.renameValue = value
                        })

                      Button('保存', { type: ButtonType.Normal, stateEffect: true })
                        .fontSize(12)
                        .onClick(() => this.onRenameSave(session.id))

                      Button('取消', { type: ButtonType.Normal, stateEffect: true })
                        .fontSize(12)
                        .onClick(() => this.onRenameCancel())
                    }
                    .width('100%')
                    .padding(12)
                    .margin({ bottom: 8 })
                    .backgroundColor('#fffbe6')
                    .borderRadius(4)
                    .gap(8)
                    .alignItems(VerticalAlign.Center)
                  } else {
                    // Normal display mode
                    Column() {
                      Row() {
                        Column() {
                          Text(session.name + (this.currentSessionId === session.id ? '（当前）' : ''))
                            .fontSize(14)
                            .fontWeight(FontWeight.Bold)

                          Text(`状态：${session.status || '未知'}`)
                            .fontSize(12)
                            .fontColor('#8c8c8c')
                            .margin({ top: 4 })

                          Text(`更新于：${this.formatDateTime(session.updatedAt)}`)
                            .fontSize(12)
                            .fontColor('#8c8c8c')
                            .margin({ top: 2 })
                        }
                        .layoutWeight(1)
                        .alignItems(HorizontalAlign.Start)

                        Row() {
                          Button('打开', { type: ButtonType.Normal, stateEffect: true })
                            .fontSize(12)
                            .width(50)
                            .onClick(() => this.onOpen(session.id))
                            .enabled(!this.isLoading && this.currentSessionId !== session.id)

                          Button('重命名', { type: ButtonType.Normal, stateEffect: true })
                            .fontSize(12)
                            .width(50)
                            .onClick(() => this.onRenameStart(session.id, session.name))
                            .enabled(!this.isLoading && !this.exporting)

                          Button('导出', { type: ButtonType.Normal, stateEffect: true })
                            .fontSize(12)
                            .width(50)
                            .onClick(() => this.onExportJSON(session.id, session.name))
                            .enabled(!this.isLoading && !this.exporting)

                          Button('删除', { type: ButtonType.Normal, stateEffect: true })
                            .fontSize(12)
                            .width(50)
                            .fontColor('#ff4d4f')
                            .onClick(() => this.onDelete(session.id))
                            .enabled(!this.isLoading && !this.exporting)
                        }
                        .gap(4)
                      }
                      .width('100%')
                      .padding(12)
                      .justifyContent(FlexAlign.SpaceBetween)
                      .alignItems(VerticalAlign.Top)
                      .gap(12)
                    }
                    .width('100%')
                    .padding(0)
                    .margin({ bottom: 8 })
                    .backgroundColor(this.currentSessionId === session.id ? '#f6ffed' : '#f5f5f5')
                    .borderRadius(4)
                  }
                }, (session: any) => session.id)
              }
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
