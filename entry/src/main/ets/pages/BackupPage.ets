/*
 * 文件标注：AI 生成 —— 数据备份/恢复页（通用 UI 脚手架）
 *
 * 可视化 UI 层 · 备份与恢复
 * 一键导出全量数据（画像/历史/日志/饮食/目标/设置/头像等）：
 *   沙箱快速备份 + 系统文件选择器导出到公共目录（换机/重装可带走）；
 * 恢复支持沙箱备份与外部文件两种来源，恢复前弹窗确认覆盖，并校验文件结构与版本号。
 * 纯本地操作，不分享、不联网；文件选择由系统选择器完成，无需申请权限。
 */
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { ThemeManager } from '../theme/ThemeManager';
import { SectionCard } from '../components/SectionCard';
import { BackgroundLayer } from '../components/BackgroundLayer';
import { IconBadge } from '../components/IconBadge';
import { BackupService, SandboxBackupInfo } from '../data/BackupService';

@Entry
@Component
struct BackupPage {
  @State theme: ThemeManager = ThemeManager.instance;
  @State lastExportPath: string = '';
  @State hasBackup: boolean = false;
  @State backupInfoText: string = '';
  @State statusText: string = '';

  aboutToAppear(): void {
    this.refreshBackupInfo();
  }

  /** 刷新沙箱备份摘要（是否存在 / 导出时间 / 大小） */
  private refreshBackupInfo(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const info: SandboxBackupInfo = BackupService.sandboxBackupInfo(context);
    this.hasBackup = info.exists;
    this.backupInfoText = info.exists ?
      `沙箱备份：${info.exportedAt.length > 0 ? info.exportedAt : '时间未知'} · 约 ${info.sizeKb} KB` : '';
  }

  private doExport(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    try {
      const path: string = BackupService.exportAll(context);
      this.lastExportPath = path;
      this.refreshBackupInfo();
      this.statusText = '导出成功，文件已保存到应用沙箱';
      promptAction.showToast({ message: '备份导出成功' });
    } catch (err) {
      this.statusText = `导出失败：${(err as Error).message}`;
    }
  }

  /** 导出到系统文件选择器指定的公共目录（换机/重装可带走；用户主动选择，系统授权，无需权限） */
  private doExportToFolder(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const now: Date = new Date();
    const stamp: string = `${now.getFullYear()}${`${now.getMonth() + 1}`.padStart(2, '0')}` +
      `${`${now.getDate()}`.padStart(2, '0')}_${`${now.getHours()}`.padStart(2, '0')}` +
      `${`${now.getMinutes()}`.padStart(2, '0')}`;
    const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    options.newFileNames = [`henglian_backup_${stamp}.json`];
    const docPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    docPicker.save(options).then((uris: string[]) => {
      if (uris.length === 0) {
        return; // 用户取消，保持静默
      }
      try {
        BackupService.exportToUri(context, uris[0]);
        this.statusText = '已导出到你选择的位置，换机/重装后可凭此文件恢复';
        promptAction.showToast({ message: '已导出到文件夹' });
      } catch (err) {
        this.statusText = `导出失败：${(err as Error).message}`;
      }
    }).catch((err: Error) => {
      this.statusText = `导出失败：${err.message}`;
    });
  }

  /** 从系统文件选择器选中的备份文件恢复（先二次确认覆盖） */
  private pickRestoreFile(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    const docPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    docPicker.select(options).then((uris: string[]) => {
      if (uris.length === 0) {
        return; // 用户取消，保持静默
      }
      const uri: string = uris[0];
      AlertDialog.show({
        title: '恢复备份',
        message: '恢复将用所选备份文件覆盖当前全部本地数据（画像/历史/日志/饮食/目标/设置/头像），且不可撤销。确定继续吗？',
        primaryButton: {
          value: '取消',
          action: () => {
          }
        },
        secondaryButton: {
          value: '覆盖恢复',
          action: () => {
            try {
              const count: number = BackupService.restoreFromUri(context, uri);
              this.refreshBackupInfo();
              this.statusText = `恢复完成，共写入 ${count} 条键值。建议重启页面后查看数据。`;
              promptAction.showToast({ message: '恢复完成' });
            } catch (err) {
              this.statusText = `恢复失败：${(err as Error).message}`;
            }
          }
        }
      });
    }).catch((err: Error) => {
      this.statusText = `恢复失败：${err.message}`;
    });
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
      this.refreshBackupInfo();
      this.statusText = `恢复完成，共写入 ${count} 条键值。建议重启页面后查看数据。`;
      promptAction.showToast({ message: '恢复完成' });
    } catch (err) {
      this.statusText = `恢复失败：${(err as Error).message}`;
    }
  }

  build() {
    // 根布局：背景层（最底，固定不滚动）+ 原内容列
    Stack() {
      BackgroundLayer({ theme: this.theme })
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
          Text('全部本地数据导出为单个 JSON 文件（存沙箱，不联网）')
            .fontSize(13)
            .fontColor(this.theme.palette.secondaryText)
            .lineHeight(19)
          Row({ space: 12 }) {
            IconBadge({ theme: this.theme, iconRes: 'app.media.ic_export', tone: 'blue', badgeSize: 40 })
            Column({ space: 2 }) {
              Text('导出全量备份')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.theme.palette.primaryText)
              Text('导出单文件到应用沙箱')
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor(this.theme.palette.secondaryText)
              .accessibilityLevel('no')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(12)
          .margin({ top: 12 })
          .borderRadius(16)
          .backgroundColor(this.theme.palette.inputBackground)
          .stateStyles({
            pressed: { .scale({ x: 0.97, y: 0.97 }) },
            normal: { .scale({ x: 1.0, y: 1.0 }) }
          })
          .accessibilityText('导出全部数据到沙箱文件')
          .onClick(() => {
            this.doExport();
          })
          Row({ space: 12 }) {
            IconBadge({ theme: this.theme, iconRes: 'app.media.ic_export', tone: 'green', badgeSize: 40 })
            Column({ space: 2 }) {
              Text('导出到文件夹')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.theme.palette.primaryText)
              Text('系统文件选择器保存到公共目录，换机/重装可带走')
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor(this.theme.palette.secondaryText)
              .accessibilityLevel('no')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(12)
          .margin({ top: 10 })
          .borderRadius(16)
          .backgroundColor(this.theme.palette.inputBackground)
          .stateStyles({
            pressed: { .scale({ x: 0.97, y: 0.97 }) },
            normal: { .scale({ x: 1.0, y: 1.0 }) }
          })
          .accessibilityText('导出全部数据到文件夹')
          .onClick(() => {
            this.doExportToFolder();
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
          Row({ space: 12 }) {
            IconBadge({ theme: this.theme, iconRes: 'app.media.ic_import', tone: 'red', badgeSize: 40 })
            Column({ space: 2 }) {
              Text('从备份文件恢复')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.hasBackup ? this.theme.palette.primaryText : this.theme.palette.secondaryText)
              Text('覆盖当前全部本地数据，恢复前会二次确认')
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor(this.theme.palette.secondaryText)
              .accessibilityLevel('no')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(12)
          .margin({ top: 12 })
          .borderRadius(16)
          .backgroundColor(this.theme.palette.inputBackground)
          .opacity(this.hasBackup ? 1 : 0.5)
          .stateStyles({
            pressed: { .scale({ x: 0.97, y: 0.97 }) },
            normal: { .scale({ x: 1.0, y: 1.0 }) }
          })
          .accessibilityText('从备份文件覆盖恢复全部数据')
          .onClick(() => {
            if (this.hasBackup) {
              this.confirmRestore();
            }
          })
          if (this.backupInfoText.length > 0) {
            Text(this.backupInfoText)
              .fontSize(11)
              .fontColor(this.theme.palette.secondaryText)
              .margin({ top: 8 })
          }
          Row({ space: 12 }) {
            IconBadge({ theme: this.theme, iconRes: 'app.media.ic_import', tone: 'orange', badgeSize: 40 })
            Column({ space: 2 }) {
              Text('选择备份文件恢复')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.theme.palette.primaryText)
              Text('从文件夹选取之前导出的备份文件')
                .fontSize(11)
                .fontColor(this.theme.palette.secondaryText)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor(this.theme.palette.secondaryText)
              .accessibilityLevel('no')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(12)
          .margin({ top: 10 })
          .borderRadius(16)
          .backgroundColor(this.theme.palette.inputBackground)
          .stateStyles({
            pressed: { .scale({ x: 0.97, y: 0.97 }) },
            normal: { .scale({ x: 1.0, y: 1.0 }) }
          })
          .accessibilityText('从文件夹选择备份文件恢复')
          .onClick(() => {
            this.pickRestoreFile();
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
    }
    .width('100%')
    .height('100%')
  }
}
