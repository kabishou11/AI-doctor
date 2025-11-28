import { getAppContext } from '../../common/AppContext'
import { Doctor, ConsultationSettings, LinkedConsultation } from '../../common/models/index'
import { Logger } from '../../common/utils/Logger'

const TAG = 'ConsultationSettingsModal'

@Component
export struct ConsultationSettingsModal {
  @State consultationName: string = ''
  @State globalSystemPrompt: string = ''
  @State summaryPrompt: string = ''
  @State turnOrder: string = 'random'
  @State maxRoundsWithoutElimination: number = 3
  @State consultDoctors: Doctor[] = []
  @State globalDoctors: Doctor[] = []
  @State linkedConsultations: LinkedConsultation[] = []
  @State selectedTab: number = 0
  @State isLoading: boolean = false
  @State selectedDoctorToAdd: string = ''
  @State selectedLinkedIds: string[] = []

  onClose?: () => void

  aboutToAppear() {
    this.loadSettings()
  }

  loadSettings() {
    try {
      const appCtx = getAppContext()
      const globalConfig = appCtx.getGlobalConfigStore()
      const consult = appCtx.getConsult()

      // Load consultation data
      this.consultationName = consult.getConsultationName() || ''
      const settings = consult.getSettings()
      this.globalSystemPrompt = settings?.globalSystemPrompt || ''
      this.summaryPrompt = settings?.summaryPrompt || ''
      this.turnOrder = settings?.turnOrder || 'random'
      this.maxRoundsWithoutElimination = settings?.maxRoundsWithoutElimination || 3

      // Load consultation doctors
      this.consultDoctors = JSON.parse(JSON.stringify(consult.getDoctors()))

      // Load global doctors
      this.globalDoctors = JSON.parse(JSON.stringify(globalConfig.doctors))

      // Load linked consultations
      this.linkedConsultations = JSON.parse(JSON.stringify(consult.getLinkedConsultations() || []))
      this.selectedLinkedIds = this.linkedConsultations.map(lc => lc.sourceId || lc.id)
    } catch (e) {
      Logger.error(TAG, `Failed to load settings: ${e}`)
    }
  }

  onSave() {
    try {
      this.isLoading = true
      const appCtx = getAppContext()
      const consult = appCtx.getConsult()
      const sessions = appCtx.getSessions()

      // Update consultation data
      consult.setConsultationName(this.consultationName)

      const settings = new ConsultationSettings({
        globalSystemPrompt: this.globalSystemPrompt,
        summaryPrompt: this.summaryPrompt,
        turnOrder: this.turnOrder,
        maxRoundsWithoutElimination: this.maxRoundsWithoutElimination
      })
      consult.setSettings(settings)
      consult.setDoctors(this.consultDoctors)
      consult.setLinkedConsultations(this.linkedConsultations)

      // Update session name if needed
      if (this.consultationName.trim() && sessions.currentId) {
        sessions.rename(sessions.currentId, this.consultationName.trim()).then(() => {
          this.isLoading = false
          this.onClose?.()
          Logger.info(TAG, 'Consultation settings saved successfully')
        }).catch((e) => {
          Logger.error(TAG, `Failed to update session: ${e}`)
          this.isLoading = false
        })
      } else {
        this.isLoading = false
        this.onClose?.()
      }
    } catch (e) {
      Logger.error(TAG, `Save error: ${e}`)
      this.isLoading = false
    }
  }

  getAvailableGlobalDoctors(): Doctor[] {
    const included = new Set(this.consultDoctors.map(d => d.id))
    return this.globalDoctors.filter(d => !included.has(d.id))
  }

  addDoctorToConsult() {
    if (!this.selectedDoctorToAdd) return

    const doctor = this.globalDoctors.find(d => d.id === this.selectedDoctorToAdd)
    if (doctor) {
      const newDoctor = JSON.parse(JSON.stringify(doctor))
      newDoctor.status = 'active'
      newDoctor.votes = 0
      this.consultDoctors = [...this.consultDoctors, newDoctor]
      this.selectedDoctorToAdd = ''
    }
  }

  addAllDoctorsToConsult() {
    const available = this.getAvailableGlobalDoctors()
    const newDoctors = available.map(d => {
      const copy = JSON.parse(JSON.stringify(d))
      copy.status = 'active'
      copy.votes = 0
      return copy
    })
    this.consultDoctors = [...this.consultDoctors, ...newDoctors]
  }

  removeConsultDoctor(id: string) {
    this.consultDoctors = this.consultDoctors.filter(d => d.id !== id)
  }

  clearConsultDoctors() {
    this.consultDoctors = []
  }

  clearLinkedConsultations() {
    this.linkedConsultations = []
    this.selectedLinkedIds = []
  }

  buildConsultSettingsTab(): void {
    Scroll() {
      Column() {
        Text('问诊参数')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        Column({ space: 8 }) {
          Text('问诊名称:')
            .fontSize(12)

          TextInput({ placeholder: '输入问诊名称', text: this.consultationName })
            .width('100%')
            .onChange((value) => {
              this.consultationName = value
            })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Column({ space: 8 }) {
          Text('当前会诊系统提示词:')
            .fontSize(12)

          TextArea({ placeholder: '输入系统提示词', text: this.globalSystemPrompt })
            .height(120)
            .onChange((value) => {
              this.globalSystemPrompt = value
            })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Column({ space: 8 }) {
          Text('最终总结提示词:')
            .fontSize(12)

          TextArea({ placeholder: '输入总结提示词', text: this.summaryPrompt })
            .height(120)
            .onChange((value) => {
              this.summaryPrompt = value
            })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Column({ space: 8 }) {
          Text('发言顺序:')
            .fontSize(12)

          Row({ space: 16 }) {
            Radio({ value: 'random', group: 'turnOrder' })
              .checked(this.turnOrder === 'random')
              .onChange((isChecked) => {
                if (isChecked) this.turnOrder = 'random'
              })
            Text('随机')

            Radio({ value: 'custom', group: 'turnOrder' })
              .checked(this.turnOrder === 'custom')
              .onChange((isChecked) => {
                if (isChecked) this.turnOrder = 'custom'
              })
            Text('按医生列表顺序')
          }
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: 16 })

        Column({ space: 8 }) {
          Text('连续未标注的最大轮数:')
            .fontSize(12)

          TextInput({ placeholder: '数值', text: this.maxRoundsWithoutElimination.toString() })
            .onChange((value) => {
              this.maxRoundsWithoutElimination = Math.max(1, parseInt(value) || 3)
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
    }
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
  }

  buildConsultDoctorsTab(): void {
    Scroll() {
      Column() {
        Text('问诊医生')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        Column({ space: 12 }) {
          Row() {
            Select(this.getAvailableGlobalDoctors().map(d => ({
              value: d.id,
              value: `${d.name} (${d.provider} • ${d.model})`
            })))
              .layoutWeight(1)
              .value(this.selectedDoctorToAdd)
              .onSelect((index, value) => {
                this.selectedDoctorToAdd = value
              })

            Button('添加', { type: ButtonType.Normal, stateEffect: true })
              .width(60)
              .onClick(() => this.addDoctorToConsult())

            Button('全部', { type: ButtonType.Normal, stateEffect: true })
              .width(60)
              .onClick(() => this.addAllDoctorsToConsult())

            Button('清空', { type: ButtonType.Normal, stateEffect: true })
              .width(60)
              .fontColor('#ff4d4f')
              .onClick(() => this.clearConsultDoctors())
          }
          .width('100%')
          .gap(4)

          if (this.consultDoctors.length === 0) {
            Text('暂无医生')
              .fontSize(14)
              .fontColor('#8c8c8c')
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 24 })
          } else {
            ForEach(this.consultDoctors, (doctor: Doctor) => {
              Row() {
                Column() {
                  Text(doctor.name)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)

                  Text(`${doctor.provider} • ${doctor.model}`)
                    .fontSize(12)
                    .fontColor('#8c8c8c')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Button('移除', { type: ButtonType.Normal, stateEffect: true })
                  .fontSize(12)
                  .fontColor('#ff4d4f')
                  .onClick(() => this.removeConsultDoctor(doctor.id))
              }
              .width('100%')
              .padding(12)
              .margin({ bottom: 8 })
              .backgroundColor('#f5f5f5')
              .borderRadius(4)
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)
            }, (doctor: Doctor) => doctor.id)
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
    }
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
  }

  buildLinkedConsultationsTab(): void {
    Scroll() {
      Column() {
        Text('关联问诊')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        Column({ space: 12 }) {
          Row() {
            Text('关联已结束的问诊作为参考')
              .fontSize(12)
              .layoutWeight(1)

            Button('清空', { type: ButtonType.Normal, stateEffect: true })
              .width(60)
              .fontColor('#ff4d4f')
              .onClick(() => this.clearLinkedConsultations())
          }
          .width('100%')
          .margin({ bottom: 12 })

          if (this.linkedConsultations.length === 0) {
            Text('暂无关联问诊')
              .fontSize(14)
              .fontColor('#8c8c8c')
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 24 })
          } else {
            ForEach(this.linkedConsultations, (linked: LinkedConsultation) => {
              Column() {
                Row() {
                  Text(linked.consultationName || '未命名问诊')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .layoutWeight(1)

                  Button('移除', { type: ButtonType.Normal, stateEffect: true })
                    .fontSize(12)
                    .fontColor('#ff4d4f')
                    .onClick(() => {
                      this.linkedConsultations = this.linkedConsultations.filter(l => l.id !== linked.id)
                      this.selectedLinkedIds = this.selectedLinkedIds.filter(id => id !== linked.sourceId)
                    })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)
                .margin({ bottom: 8 })

                Column({ space: 4 }) {
                  Text(`患者: ${linked.patientName || '未知'}, ${linked.patientGender || '未知'}, ${linked.patientAge || '未知'}岁`)
                    .fontSize(12)
                    .fontColor('#595959')

                  if (linked.pastHistory) {
                    Text(`既往疾病: ${linked.pastHistory}`)
                      .fontSize(11)
                      .fontColor('#8c8c8c')
                  }

                  if (linked.currentProblem) {
                    Text(`本次问题: ${linked.currentProblem}`)
                      .fontSize(11)
                      .fontColor('#8c8c8c')
                  }
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(12)
              .margin({ bottom: 8 })
              .backgroundColor('#f5f5f5')
              .borderRadius(4)
            }, (linked: LinkedConsultation) => linked.id)
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
    }
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
  }

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

          // Tabs
          Tabs({ barPosition: BarPosition.Start }) {
            TabContent() {
              this.buildConsultSettingsTab()
            }
            .tabBar('问诊参数')

            TabContent() {
              this.buildConsultDoctorsTab()
            }
            .tabBar('问诊医生')

            TabContent() {
              this.buildLinkedConsultationsTab()
            }
            .tabBar('关联问诊')
          }
          .width('100%')
          .height('calc(100% - 100px)')
          .barHeight(40)

          // Footer buttons
          Row() {
            Button('取消', { type: ButtonType.Normal, stateEffect: true })
              .layoutWeight(1)
              .onClick(() => this.onClose?.())

            Button('保存', { type: ButtonType.Normal, stateEffect: true })
              .layoutWeight(1)
              .backgroundColor('#1890ff')
              .fontColor('#ffffff')
              .onClick(() => this.onSave())
              .enabled(!this.isLoading)
          }
          .width('100%')
          .height(50)
          .padding({ left: 16, right: 16, bottom: 16 })
          .gap(8)
        }
        .width('90%')
        .height('80%')
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
