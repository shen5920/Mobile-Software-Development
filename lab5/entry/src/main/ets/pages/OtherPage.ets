import router from '@ohos.router';

@Entry
@Component
struct OtherPage {
  uiContext = this.getUIContext();
  @StorageLink('topRectHeight') topRectHeight: number = 0;

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('←')
          .fontSize(26)
          .fontColor('#000000')
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          });
        Text('其他')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ left: 8 });
        Blank();
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 8 })
      .margin({ top: this.uiContext.px2vp(this.topRectHeight) });

      Scroll() {
        Column() {
          // ===== 绘图分区 =====
          this.buildSectionTitle('绘图');
          this.buildEntryRow('函数绘图', '∿', () => {
            router.pushUrl({ url: 'pages/DrawPage' });
          });

          // ===== 日期计算分区 =====
          this.buildSectionTitle('日期计算');
          this.buildEntryRow('日期差计算', '日', () => {
            router.pushUrl({ url: 'pages/DateCalcPage' });
          });

          // ===== 换算分区 =====
          this.buildSectionTitle('换算');
          this.buildEntryRow('单位换算', '⇄', () => {
            router.pushUrl({ url: 'pages/ConvertPage' });
          });
        }
        .width('100%')
        .padding({ bottom: 24 });
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2');
  }

  @Builder
  buildSectionTitle(title: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333');
    }
    .width('100%')
    .padding({ left: 20, top: 20, bottom: 10 });
  }

  @Builder
  buildEntryRow(name: string, icon: string, action: () => void) {
    Row() {
      Text(icon)
        .fontSize(22)
        .width(40)
        .textAlign(TextAlign.Center);
      Text(name)
        .fontSize(18)
        .fontColor('#000000')
        .margin({ left: 8 });
      Blank();
      Text('>')
        .fontSize(20)
        .fontColor('#AAAAAA')
        .margin({ right: 16 });
    }
    .width('100%')
    .height(60)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      action();
    });
  }
}
