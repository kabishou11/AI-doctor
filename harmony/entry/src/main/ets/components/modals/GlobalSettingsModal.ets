import { getAppContext } from '../../common/AppContext'
import { Doctor, PresetPrompt, ImageRecognitionConfig, ConsultationSettings } from '../../common/models/index'
import { Logger } from '../../common/utils/Logger'
import { FileUtils } from '../../common/utils/FileUtils'

const TAG = 'GlobalSettingsModal'

@Component
export struct GlobalSettingsModal {
  @State doctors: Doctor[] = []
  @State presetPrompts: PresetPrompt[] = []
  @State imageRecognition: ImageRecognitionConfig = new ImageRecognitionConfig()
  @State globalSystemPrompt: string = ''
  @State summaryPrompt: string = ''
  @State turnOrder: string = 'random'
  @State maxRoundsWithoutElimination: number = 3
  @State selectedTab: number = 0
  @State isLoading: boolean = false
  @State editingDoctorId: string | null = null
  @State editingPresetId: string | null = null

  onClose?: () => void

  aboutToAppear() {
    this.loadSettings()
  }

  loadSettings() {
    try {
      const appCtx = getAppContext()
      const globalConfig = appCtx.getGlobalConfigStore()
      const consult = appCtx.getConsult()

      // Deep copy to avoid direct mutations
      this.doctors = JSON.parse(JSON.stringify(globalConfig.doctors))
      this.presetPrompts = JSON.parse(JSON.stringify(globalConfig.presetPrompts))
      this.imageRecognition = new ImageRecognitionConfig(JSON.parse(JSON.stringify(globalConfig.imageRecognition)))

      const settings = consult.getSettings()
      this.globalSystemPrompt = settings?.globalSystemPrompt || ''
      this.summaryPrompt = settings?.summaryPrompt || ''
      this.turnOrder = settings?.turnOrder || 'random'
      this.maxRoundsWithoutElimination = settings?.maxRoundsWithoutElimination || 3
    } catch (e) {
      Logger.error(TAG, `Failed to load settings: ${e}`)
    }
  }

  onSave() {
    try {
      this.isLoading = true
      const appCtx = getAppContext()
      const globalConfig = appCtx.getGlobalConfigStore()
      const consult = appCtx.getConsult()

      // Save doctors and preset prompts
      globalConfig.setDoctors(this.doctors).then(() => {
        globalConfig.setPresetPrompts(this.presetPrompts).then(() => {
          globalConfig.setImageRecognition(this.imageRecognition).then(() => {
            // Save consultation settings
            const newSettings = new ConsultationSettings({
              globalSystemPrompt: this.globalSystemPrompt,
              summaryPrompt: this.summaryPrompt,
              turnOrder: this.turnOrder,
              maxRoundsWithoutElimination: this.maxRoundsWithoutElimination
            })
            consult.setSettings(newSettings)
            this.isLoading = false
            this.onClose?.()
            Logger.info(TAG, 'Settings saved successfully')
          }).catch((e) => {
            Logger.error(TAG, `Failed to save image recognition: ${e}`)
            this.isLoading = false
          })
        }).catch((e) => {
          Logger.error(TAG, `Failed to save presets: ${e}`)
          this.isLoading = false
        })
      }).catch((e) => {
        Logger.error(TAG, `Failed to save doctors: ${e}`)
        this.isLoading = false
      })
    } catch (e) {
      Logger.error(TAG, `Save error: ${e}`)
      this.isLoading = false
    }
  }

  addDoctor() {
    const id = `doc-${Date.now()}-${Math.floor(Math.random() * 10000)}`
    const newDoctor = new Doctor({
      id,
      name: '新医生',
      provider: 'openai',
      model: 'gpt-4o-mini',
      apiKey: '',
      baseUrl: '',
      customPrompt: ''
    })
    this.doctors = [...this.doctors, newDoctor]
  }

  removeDoctor(index: number) {
    this.doctors.splice(index, 1)
    this.doctors = [...this.doctors]
  }

  updateDoctor(index: number, field: string, value: any) {
    const doctor = this.doctors[index]
    if (doctor) {
      doctor[field] = value
      this.doctors[index] = doctor
      this.doctors = [...this.doctors]
    }
  }

  addPresetPrompt() {
    const id = `preset-${Date.now()}-${Math.floor(Math.random() * 10000)}`
    const newPreset = new PresetPrompt({
      id,
      name: '新预设',
      prompt: ''
    })
    this.presetPrompts = [...this.presetPrompts, newPreset]
  }

  removePresetPrompt(index: number) {
    this.presetPrompts.splice(index, 1)
    this.presetPrompts = [...this.presetPrompts]
  }

  updatePresetPrompt(index: number, field: string, value: any) {
    const preset = this.presetPrompts[index]
    if (preset) {
      preset[field] = value
      this.presetPrompts[index] = preset
      this.presetPrompts = [...this.presetPrompts]
    }
  }

  exportSettings() {
    try {
      const data = {
        doctors: this.doctors,
        presetPrompts: this.presetPrompts,
        imageRecognition: this.imageRecognition,
        settings: {
          globalSystemPrompt: this.globalSystemPrompt,
          summaryPrompt: this.summaryPrompt,
          turnOrder: this.turnOrder,
          maxRoundsWithoutElimination: this.maxRoundsWithoutElimination
        }
      }
      const json = JSON.stringify(data, null, 2)
      const fileName = FileUtils.formatFileName('全局设置', 'json')
      FileUtils.exportJSON(fileName, json).then(() => {
        Logger.info(TAG, `Settings exported as ${fileName}`)
      }).catch((e) => {
        Logger.error(TAG, `Export failed: ${e}`)
      })
    } catch (e) {
      Logger.error(TAG, `Export error: ${e}`)
    }
  }

  buildDoctorsTab(): void {
    Scroll() {
      Column() {
        Text('医生配置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        ForEach(this.doctors, (doctor: Doctor, index: number) => {
          Column() {
            Row() {
              Text(doctor.name || '未命名医生')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)

              Button('删除', { type: ButtonType.Normal, stateEffect: true })
                .fontSize(12)
                .fontColor('#ff4d4f')
                .onClick(() => this.removeDoctor(index))
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 12 })

            Column({ space: 8 }) {
              Row() {
                Text('医生名称:')
                  .width(100)

                TextInput({ placeholder: '医生名称', text: doctor.name })
                  .layoutWeight(1)
                  .onChange((value) => this.updateDoctor(index, 'name', value))
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Row() {
                Text('供应商:')
                  .width(100)

                Select([
                  { value: 'openai' },
                  { value: 'anthropic' },
                  { value: 'gemini' },
                  { value: 'siliconflow' },
                  { value: 'modelscope' }
                ])
                  .layoutWeight(1)
                  .value(doctor.provider)
                  .onSelect((index, value) => this.updateDoctor(index, 'provider', value))
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Row() {
                Text('模型名称:')
                  .width(100)

                TextInput({ placeholder: '模型名称', text: doctor.model })
                  .layoutWeight(1)
                  .onChange((value) => this.updateDoctor(index, 'model', value))
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Row() {
                Text('API Key:')
                  .width(100)

                TextInput({ placeholder: 'sk-...', text: doctor.apiKey })
                  .layoutWeight(1)
                  .type(InputType.Password)
                  .onChange((value) => this.updateDoctor(index, 'apiKey', value))
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Row() {
                Text('Base URL:')
                  .width(100)

                TextInput({ placeholder: '留空使用默认', text: doctor.baseUrl })
                  .layoutWeight(1)
                  .onChange((value) => this.updateDoctor(index, 'baseUrl', value))
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Column() {
                Text('自定义提示词:')
                  .fontSize(12)

                TextArea({ placeholder: '输入自定义提示词', text: doctor.customPrompt })
                  .height(80)
                  .onChange((value) => this.updateDoctor(index, 'customPrompt', value))
              }
              .width('100%')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#f9f9f9')
            .borderRadius(4)
          }
          .width('100%')
          .padding(12)
          .margin({ bottom: 12 })
          .backgroundColor('#fafafa')
          .borderRadius(4)
        }, (doctor: Doctor) => doctor.id)

        Button('+ 添加医生', { type: ButtonType.Dashed, stateEffect: true })
          .width('100%')
          .onClick(() => this.addDoctor())
      }
      .width('100%')
      .padding(12)
    }
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
  }

  buildPresetsTab(): void {
    Scroll() {
      Column() {
        Text('医生预设提示词')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        ForEach(this.presetPrompts, (preset: PresetPrompt, index: number) => {
          Column() {
            Row() {
              Text(preset.name || '未命名预设')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)

              Button('删除', { type: ButtonType.Normal, stateEffect: true })
                .fontSize(12)
                .fontColor('#ff4d4f')
                .onClick(() => this.removePresetPrompt(index))
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 12 })

            Column({ space: 8 }) {
              Row() {
                Text('预设名称:')
                  .width(100)

                TextInput({ placeholder: '预设名称', text: preset.name })
                  .layoutWeight(1)
                  .onChange((value) => this.updatePresetPrompt(index, 'name', value))
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Column() {
                Text('提示词内容:')
                  .fontSize(12)

                TextArea({ placeholder: '输入提示词', text: preset.prompt })
                  .height(100)
                  .onChange((value) => this.updatePresetPrompt(index, 'prompt', value))
              }
              .width('100%')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#f9f9f9')
            .borderRadius(4)
          }
          .width('100%')
          .padding(12)
          .margin({ bottom: 12 })
          .backgroundColor('#fafafa')
          .borderRadius(4)
        }, (preset: PresetPrompt) => preset.id)

        Button('+ 添加预设', { type: ButtonType.Dashed, stateEffect: true })
          .width('100%')
          .onClick(() => this.addPresetPrompt())
      }
      .width('100%')
      .padding(12)
    }
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
  }

  buildGlobalSettingsTab(): void {
    Scroll() {
      Column() {
        Text('全局参数')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        Column({ space: 8 }) {
          Text('全局系统提示词:')
            .fontSize(12)

          TextArea({ placeholder: '输入全局系统提示词', text: this.globalSystemPrompt })
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

          TextArea({ placeholder: '输入最终总结提示词', text: this.summaryPrompt })
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
              this.maxRoundsWithoutElimination = parseInt(value) || 3
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

  buildImageRecognitionTab(): void {
    Scroll() {
      Column() {
        Text('图片识别设置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        Row() {
          Toggle({ type: ToggleType.Checkbox, isOn: this.imageRecognition.enabled })
            .onChange((isOn) => {
              this.imageRecognition.enabled = isOn
              this.imageRecognition = new ImageRecognitionConfig(this.imageRecognition)
            })

          Text('启用图像识别功能')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ bottom: 16 })

        if (this.imageRecognition.enabled) {
          Column({ space: 8 }) {
            Text('供应商: 硅基流动 (固定)')
              .fontSize(12)
              .fontColor('#8c8c8c')

            Row() {
              Text('API Key:')
                .width(100)

              TextInput({ placeholder: 'sk-...', text: this.imageRecognition.apiKey })
                .layoutWeight(1)
                .type(InputType.Password)
                .onChange((value) => {
                  this.imageRecognition.apiKey = value
                  this.imageRecognition = new ImageRecognitionConfig(this.imageRecognition)
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: 12 })

            Row() {
              Text('模型名称:')
                .width(100)

              TextInput({ placeholder: '模型名称', text: this.imageRecognition.model })
                .layoutWeight(1)
                .onChange((value) => {
                  this.imageRecognition.model = value
                  this.imageRecognition = new ImageRecognitionConfig(this.imageRecognition)
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Row() {
              Text('Base URL:')
                .width(100)

              TextInput({ placeholder: '留空使用默认', text: this.imageRecognition.baseUrl })
                .layoutWeight(1)
                .onChange((value) => {
                  this.imageRecognition.baseUrl = value
                  this.imageRecognition = new ImageRecognitionConfig(this.imageRecognition)
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Row() {
              Text('最大并发数:')
                .width(100)

              TextInput({ placeholder: '数值', text: this.imageRecognition.maxConcurrent.toString() })
                .layoutWeight(1)
                .onChange((value) => {
                  this.imageRecognition.maxConcurrent = Math.max(1, parseInt(value) || 1)
                  this.imageRecognition = new ImageRecognitionConfig(this.imageRecognition)
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Column() {
              Text('识别提示词:')
                .fontSize(12)

              TextArea({ placeholder: '输入识别提示词', text: this.imageRecognition.prompt })
                .height(100)
                .onChange((value) => {
                  this.imageRecognition.prompt = value
                  this.imageRecognition = new ImageRecognitionConfig(this.imageRecognition)
                })
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#f9f9f9')
          .borderRadius(4)
        }
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

          // Tabs
          Tabs({ barPosition: BarPosition.Start }) {
            TabContent() {
              this.buildDoctorsTab()
            }
            .tabBar('医生配置')

            TabContent() {
              this.buildPresetsTab()
            }
            .tabBar('预设提示词')

            TabContent() {
              this.buildGlobalSettingsTab()
            }
            .tabBar('全局参数')

            TabContent() {
              this.buildImageRecognitionTab()
            }
            .tabBar('图片识别')
          }
          .width('100%')
          .height('calc(100% - 100px)')
          .barHeight(40)

          // Footer buttons
          Row() {
            Button('取消', { type: ButtonType.Normal, stateEffect: true })
              .layoutWeight(1)
              .onClick(() => this.onClose?.())

            Button('导出设置', { type: ButtonType.Normal, stateEffect: true })
              .layoutWeight(1)
              .onClick(() => this.exportSettings())

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
