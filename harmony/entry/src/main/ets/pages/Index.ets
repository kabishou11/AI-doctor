import { router } from '@kit.ArkUI'
import { Header } from '../components/Header'
import { DiscussionPane } from '../components/DiscussionPane'
import { StatusPane } from '../components/StatusPane'
import { GlobalSettingsModal } from '../components/modals/GlobalSettingsModal'
import { ConsultationSettingsModal } from '../components/modals/ConsultationSettingsModal'
import { SessionListDrawer } from '../components/drawers/SessionListDrawer'

@Entry
@Component
struct Index {
  @State globalSettingsOpen: boolean = false
  @State consultationSettingsOpen: boolean = false
  @State sessionsOpen: boolean = false

  build() {
    Column() {
      // Header with logo, title, warning, and action buttons
      Header({
        onOpenSessions: () => {
          this.sessionsOpen = true
        },
        onOpenGlobalSettings: () => {
          this.globalSettingsOpen = true
        },
        onOpenConsultationSettings: () => {
          this.consultationSettingsOpen = true
        }
      })

      // Two-column body layout
      Row() {
        // Left column: Discussion pane (2/3 width)
        DiscussionPane()
          .layoutWeight(2)

        // Right column: Status pane (1/3 width)
        StatusPane({
          onOpenSettings: () => {
            this.consultationSettingsOpen = true
          }
        })
          .layoutWeight(1)
      }
      .height('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
      .gap(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')

    // Modals and drawers
    if (this.globalSettingsOpen) {
      GlobalSettingsModal({
        onClose: () => {
          this.globalSettingsOpen = false
        }
      })
    }

    if (this.consultationSettingsOpen) {
      ConsultationSettingsModal({
        onClose: () => {
          this.consultationSettingsOpen = false
        }
      })
    }

    if (this.sessionsOpen) {
      SessionListDrawer({
        onClose: () => {
          this.sessionsOpen = false
        }
      })
    }
  }
}
