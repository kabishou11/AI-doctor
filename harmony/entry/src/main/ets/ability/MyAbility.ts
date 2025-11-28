import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { Logger } from '../utils/Logger'

const TAG: string = 'MyAbility'

export default class MyAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, `onCreate`)
  }

  onDestroy(): void {
    Logger.info(TAG, `onDestroy`)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(TAG, `onWindowStageCreate`)

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.error(TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err))
        return
      }
      Logger.info(TAG, 'Succeeded in loading the content.')
    })

    let windowClass: window.Window | undefined = undefined
    windowStage.getMainWindow((err, data) => {
      const errCode: number = err.code
      if (errCode) {
        Logger.error(TAG, 'Failed to obtain the main window. Cause: %{public}s', JSON.stringify(err))
        return
      }
      windowClass = data
      let orientation = window.Orientation.PORTRAIT
      windowClass.setPreferredOrientation(orientation, (err) => {
        if (err.code !== 0) {
          Logger.error(TAG, 'Failed to set window orientation. Cause: %{public}s', JSON.stringify(err))
        }
      })
    })
  }

  onWindowStageDestroy(): void {
    Logger.info(TAG, `onWindowStageDestroy`)
  }

  onForeground(): void {
    Logger.info(TAG, `onForeground`)
  }

  onBackground(): void {
    Logger.info(TAG, `onBackground`)
  }
}
