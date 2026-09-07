import router from '@ohos.router';

@Entry
@Component
struct DateCalcPage {
  uiContext = this.getUIContext();
  @StorageLink('topRectHeight') topRectHeight: number = 0;
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0;

  // 0=日期间隔 1=日期推算
  @State mode: number = 0;
  @State startDate: Date = new Date();
  @State endDate: Date = new Date();
  // 日期推算
  @State baseDate: Date = new Date();
  @State daysInput: string = '7';
  @State addOrMinus: number = 1; // 1=加 -1=减

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
        Text('日期计算')
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

      // 模式切换
      Row() {
        this.buildModeBtn('日期间隔', 0);
        this.buildModeBtn('日期推算', 1);
      }
      .width('100%')
      .padding(16);

      if (this.mode === 0) {
        this.buildInterval();
      } else {
        this.buildAdd();
      }
      Blank();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2');
  }

  @Builder
  buildModeBtn(label: string, idx: number) {
    Text(label)
      .fontSize(16)
      .fontColor(this.mode === idx ? '#FFFFFF' : '#333333')
      .backgroundColor(this.mode === idx ? '#00897B' : '#FFFFFF')
      .borderRadius(20)
      .height(40)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .margin({ left: idx === 0 ? 0 : 12 })
      .onClick(() => {
        this.mode = idx;
      });
  }

  // 日期间隔
  @Builder
  buildInterval() {
    Column() {
      // 开始日期
      Row() {
        Text('开始日期')
          .fontSize(18)
          .fontColor('#333333');
        Blank();
        Text(this.fmt(this.startDate))
          .fontSize(18)
          .fontColor('#FF9500');
        Text(' >')
          .fontSize(18)
          .fontColor('#AAAAAA');
      }
      .width('100%')
      .height(64)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.pickDate(this.startDate, (d: Date) => {
          this.startDate = d;
        });
      });

      // 结束日期
      Row() {
        Text('结束日期')
          .fontSize(18)
          .fontColor('#333333');
        Blank();
        Text(this.fmt(this.endDate))
          .fontSize(18)
          .fontColor('#FF9500');
        Text(' >')
          .fontSize(18)
          .fontColor('#AAAAAA');
      }
      .width('100%')
      .height(64)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16, top: 12 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.pickDate(this.endDate, (d: Date) => {
          this.endDate = d;
        });
      });

      // 结果
      Column() {
        Text('相差')
          .fontSize(16)
          .fontColor('#888888');
        Row() {
          Text(this.diffDays().toString())
            .fontSize(40)
            .fontColor('#00897B')
            .fontWeight(FontWeight.Bold);
          Text(' 天')
            .fontSize(18)
            .fontColor('#666666');
        }
        .margin({ top: 8 });
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16, top: 16 });
    }
    .width('100%');
  }

  // 日期推算
  @Builder
  buildAdd() {
    Column() {
      Row() {
        Text('基准日期')
          .fontSize(18)
          .fontColor('#333333');
        Blank();
        Text(this.fmt(this.baseDate))
          .fontSize(18)
          .fontColor('#FF9500');
        Text(' >')
          .fontSize(18)
          .fontColor('#AAAAAA');
      }
      .width('100%')
      .height(64)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.pickDate(this.baseDate, (d: Date) => {
          this.baseDate = d;
        });
      });

      Row() {
        Text('加减天数')
          .fontSize(18)
          .fontColor('#333333')
          .margin({ right: 12 });
        // 加/减切换
        Text('加')
          .fontSize(16)
          .fontColor(this.addOrMinus === 1 ? '#FFFFFF' : '#333333')
          .backgroundColor(this.addOrMinus === 1 ? '#00897B' : '#E8E8E8')
          .borderRadius(14)
          .width(44)
          .height(36)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.addOrMinus = 1;
          });
        Text('减')
          .fontSize(16)
          .fontColor(this.addOrMinus === -1 ? '#FFFFFF' : '#333333')
          .backgroundColor(this.addOrMinus === -1 ? '#00897B' : '#E8E8E8')
          .borderRadius(14)
          .width(44)
          .height(36)
          .textAlign(TextAlign.Center)
          .margin({ left: 8, right: 10 })
          .onClick(() => {
            this.addOrMinus = -1;
          });
        TextInput({ text: $$this.daysInput })
          .type(InputType.Number)
          .fontSize(18)
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(12);
        Text('天')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ left: 8 });
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16, top: 12 })
      .height(64)
      .alignItems(VerticalAlign.Center);

      // 快捷加减
      Row() {
        this.buildQuickBtn('-30');
        this.buildQuickBtn('-7');
        this.buildQuickBtn('+7');
        this.buildQuickBtn('+30');
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 });

      Column() {
        Text('结果日期')
          .fontSize(16)
          .fontColor('#888888');
        Text(this.addResult())
          .fontSize(34)
          .fontColor('#00897B')
          .fontWeight(FontWeight.Bold)
          .margin({ top: 8 });
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16, top: 16 });
    }
    .width('100%');
  }

  @Builder
  buildQuickBtn(v: string) {
    Text(v + '天')
      .fontSize(15)
      .fontColor('#00897B')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .height(34)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .margin({ left: 4, right: 4 })
      .onClick(() => {
        if (v.startsWith('-')) {
          this.addOrMinus = -1;
          this.daysInput = v.substring(1);
        } else {
          this.addOrMinus = 1;
          this.daysInput = v.substring(1);
        }
      });
  }

  private pickDate(selected: Date, cb: (d: Date) => void): void {
    DatePickerDialog.show({
      start: new Date('1970-01-01'),
      end: new Date('2100-12-31'),
      selected: selected,
      onAccept: (value: DatePickerResult) => {
        let d = new Date(value.year, value.month, value.day);
        cb(d);
      }
    });
  }

  private fmt(d: Date): string {
    let m = d.getMonth() + 1;
    let day = d.getDate();
    return d.getFullYear() + '-' + (m < 10 ? '0' + m : m.toString()) + '-'
      + (day < 10 ? '0' + day : day.toString());
  }

  // 去掉时分秒，只按天计算
  private dayStart(d: Date): number {
    let a = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    return a.getTime();
  }

  private diffDays(): number {
    let ms = this.dayStart(this.endDate) - this.dayStart(this.startDate);
    return Math.round(ms / 86400000);
  }

  private addResult(): string {
    let n = Number(this.daysInput);
    if (isNaN(n)) {
      return '请输入天数';
    }
    let d = new Date(this.baseDate.getFullYear(), this.baseDate.getMonth(), this.baseDate.getDate());
    d.setDate(d.getDate() + n * this.addOrMinus);
    return this.fmt(d);
  }
}
