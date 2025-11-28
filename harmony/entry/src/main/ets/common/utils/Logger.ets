import { hilog } from '@kit.PerformanceAnalysis'

export class Logger {
  static readonly LOG_DOMAIN = 0x0000
  static readonly LOG_TAG = 'ConsultApp'

  static debug(tag: string, message: string): void {
    hilog.debug(this.LOG_DOMAIN, tag, message)
  }

  static info(tag: string, message: string): void {
    hilog.info(this.LOG_DOMAIN, tag, message)
  }

  static warn(tag: string, message: string): void {
    hilog.warn(this.LOG_DOMAIN, tag, message)
  }

  static error(tag: string, message: string): void {
    hilog.error(this.LOG_DOMAIN, tag, message)
  }
}
