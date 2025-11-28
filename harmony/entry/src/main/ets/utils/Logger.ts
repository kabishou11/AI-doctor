import { hilog } from '@kit.PerformanceAnalysisKit'

export const Logger = {
  info(tag: string, msg: string, ...args: any[]) {
    hilog.info(0x0000, tag, msg, ...args)
  },
  warn(tag: string, msg: string, ...args: any[]) {
    hilog.warn(0x0000, tag, msg, ...args)
  },
  error(tag: string, msg: string, ...args: any[]) {
    hilog.error(0x0000, tag, msg, ...args)
  },
  debug(tag: string, msg: string, ...args: any[]) {
    hilog.debug(0x0000, tag, msg, ...args)
  }
}
