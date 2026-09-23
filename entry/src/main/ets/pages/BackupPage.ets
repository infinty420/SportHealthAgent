/*
 * 文件标注：AI 生成 —— 数据备份/恢复页（通用 UI 脚手架）
 *
 * 可视化 UI 层 · 备份与恢复
 * 一键导出全量数据（画像/历史/日志/饮食/目标/设置等）为单文件到沙箱；
 * 恢复前弹窗确认覆盖，并校验文件结构与版本号。纯本地操作，不分享、不联网。
 */
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { ThemeManager } from '../theme/ThemeManager';
import { SectionCard } from '../components/SectionCard';
import { BackupService } from '../data/BackupService';

@Entry
@Component
struct BackupPage {
  @State theme: ThemeManager = ThemeManager.instance;
  @State lastExportPath: string = '';
  @State hasBackup: boolean = false;
  @State statusText: string = '';

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.hasBackup = BackupService.backupExists(context);
  }

  private doExport(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    try {
      const path: string = BackupService.exportAll(context);
      this.lastExportPath = path;
      this.hasBackup = true;
      this.statusText = '导出成功，文件已保存到应用沙箱';
      promptAction.showToast({ message: '备份导出成功' });
    } catch (err) {
      this.statusText = `导出失败：${(err as Error).message}`;
    }
  }

  private confirmRestore(): void {
    AlertDialog.show({
      title: '恢复备份',
      message: '恢复将用备份文件覆盖当前全部本地数据（画像/历史/日志/饮食/目标/设置），且不可撤销。确定继续吗？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '覆盖恢复',
        action: () => {
          this.doRestore();
        }
      }
    });
  }

  private doRestore(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    try {
      const count: number = BackupService.restoreAll(context);
      this.statusText = `恢复完成，共写入 ${count} 条键值。建议重启页面后查看数据。`;
      promptAction.showToast({ message: '恢复完成' });
    } catch (err) {
      this.statusText = `恢复失败：${(err as Error).message}`;
    }
  }

  build() {
    Column() {
      // 顶部栏：返回 + 标题
      Row() {
        Button('← 返回')
          .fontSize(14)
          .fontColor(this.theme.palette.accent)
          .backgroundColor(this.theme.palette.inputBackground)
          .borderRadius(18)
          .height(36)
          .accessibilityText('返回上一页')
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('备份与恢复')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.palette.primaryText)
        Blank()
        Row()
          .width(64)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Column() {
        SectionCard({ theme: this.theme, title: '一键导出' }) {
          Text('把画像、历史记录、训练日志、饮食记录、目标与设置等全部本地数据导出为单个 JSON 文件（保存在应用沙箱内，不联网、不分享）。')
            .fontSize(13)
            .fontColor(this.theme.palette.secondaryText)
            .lineHeight(19)
          Button('导出全量备份')
            .fontSize(14)
            .fontColor(this.theme.palette.onAccent)
            .backgroundColor(this.theme.palette.accent)
            .borderRadius(20)
            .width('100%')
            .height(40)
            .margin({ top: 12 })
            .accessibilityText('导出全部数据到沙箱文件')
            .onClick(() => {
              this.doExport();
            })
          if (this.lastExportPath.length > 0) {
            Text(this.lastExportPath)
              .fontSize(11)
              .fontColor(this.theme.palette.secondaryText)
              .margin({ top: 8 })
          }
        }

        SectionCard({ theme: this.theme, title: '从备份恢复' }) {
          Text(this.hasBackup ? '检测到沙箱内存在备份文件，可以执行恢复。' : '沙箱内暂无备份文件，请先执行导出。')
            .fontSize(13)
            .fontColor(this.theme.palette.secondaryText)
            .lineHeight(19)
          Button('从备份文件恢复')
            .fontSize(14)
            .fontColor(this.hasBackup ? this.theme.palette.onAccent : this.theme.palette.secondaryText)
            .backgroundColor(this.hasBackup ? this.theme.palette.danger : this.theme.palette.inputBackground)
            .borderRadius(20)
            .width('100%')
            .height(40)
            .margin({ top: 12 })
            .enabled(this.hasBackup)
            .accessibilityText('从备份文件覆盖恢复全部数据')
            .onClick(() => {
              this.confirmRestore();
            })
        }

        if (this.statusText.length > 0) {
          SectionCard({ theme: this.theme, title: '状态' }) {
            Text(this.statusText)
              .fontSize(13)
              .fontColor(this.theme.palette.primaryText)
              .lineHeight(19)
          }
        }
      }
      .padding({ left: 16, right: 16 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.palette.pageBackground)
  }
}
