/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import router from '@ohos.router';

interface Category {
  name: string;
  icon: string;
}

interface UnitDef {
  name: string;
  symbol: string;
  factor: number; // 1个该单位 = factor个基准单位
  enName?: string; // 英文名称（用于搜索和首字母分组）
}

interface UnitGroup {
  letter: string;
  units: UnitDef[];
}

@Entry
@Component
struct ConvertPage {
  @State currentCategory: string = '';
  @State fromValue: string = '1';
  @State toValue: string = '';
  @State activeSide: number = 0; // 0=上方输入 1=下方输入
  @State fromIndex: number = 0;
  @State toIndex: number = 1;
  // 单位选择面板
  @State showPicker: boolean = false;
  @State pickerSide: number = 0; // 0=选from 1=选to
  @State searchText: string = '';
  uiContext = this.getUIContext();
  @StorageLink('topRectHeight') topRectHeight: number = 0;
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0;

  // 换算分类
  private categories: Category[] = [
    { name: '汇率', icon: '¥' },
    { name: '长度', icon: '━' },
    { name: '面积', icon: '▢' },
    { name: '体积', icon: '◫' },
    { name: '重量', icon: '⚖' },
    { name: '温度', icon: '°' },
    { name: '速度', icon: '»' },
    { name: '压强', icon: '≋' },
    { name: '功率', icon: '⚡' },
    { name: '进制', icon: '01' }
  ];

  // 汇率（基准：人民币，1单位外币=factor人民币；按英文名称A-Z排序）
  private currencyUnits: UnitDef[] = [
    { name: '澳大利亚元', symbol: 'AUD', factor: 4.72, enName: 'Australian Dollar' },
    { name: '巴西雷亚尔', symbol: 'BRL', factor: 1.39, enName: 'Brazilian Real' },
    { name: '加元', symbol: 'CAD', factor: 5.24, enName: 'Canadian Dollar' },
    { name: '瑞士法郎', symbol: 'CHF', factor: 8.12, enName: 'Swiss Franc' },
    { name: '人民币', symbol: 'CNY', factor: 1, enName: 'Chinese Yuan' },
    { name: '丹麦克朗', symbol: 'DKK', factor: 1.05, enName: 'Danish Krone' },
    { name: '欧元', symbol: 'EUR', factor: 7.82, enName: 'Euro' },
    { name: '英镑', symbol: 'GBP', factor: 9.18, enName: 'British Pound' },
    { name: '港币', symbol: 'HKD', factor: 0.918, enName: 'Hong Kong Dollar' },
    { name: '印度卢比', symbol: 'INR', factor: 0.086, enName: 'Indian Rupee' },
    { name: '日元', symbol: 'JPY', factor: 0.0465, enName: 'Japanese Yen' },
    { name: '韩元', symbol: 'KRW', factor: 0.00526, enName: 'South Korean Won' },
    { name: '墨西哥比索', symbol: 'MXN', factor: 0.38, enName: 'Mexican Peso' },
    { name: '马来西亚林吉特', symbol: 'MYR', factor: 1.54, enName: 'Malaysian Ringgit' },
    { name: '挪威克朗', symbol: 'NOK', factor: 0.67, enName: 'Norwegian Krone' },
    { name: '新西兰元', symbol: 'NZD', factor: 4.32, enName: 'New Zealand Dollar' },
    { name: '俄罗斯卢布', symbol: 'RUB', factor: 0.078, enName: 'Russian Ruble' },
    { name: '瑞典克朗', symbol: 'SEK', factor: 0.69, enName: 'Swedish Krona' },
    { name: '新加坡元', symbol: 'SGD', factor: 5.32, enName: 'Singapore Dollar' },
    { name: '泰铢', symbol: 'THB', factor: 0.196, enName: 'Thai Baht' },
    { name: '土耳其里拉', symbol: 'TRY', factor: 0.21, enName: 'Turkish Lira' },
    { name: '美元', symbol: 'USD', factor: 7.16, enName: 'US Dollar' },
    { name: '南非兰特', symbol: 'ZAR', factor: 0.39, enName: 'South African Rand' }
  ];

  // 长度（基准：米）
  private lengthUnits: UnitDef[] = [
    { name: '毫米', symbol: 'mm', factor: 0.001 },
    { name: '厘米', symbol: 'cm', factor: 0.01 },
    { name: '米', symbol: 'm', factor: 1 },
    { name: '千米', symbol: 'km', factor: 1000 },
    { name: '英寸', symbol: 'in', factor: 0.0254 },
    { name: '英尺', symbol: 'ft', factor: 0.3048 },
    { name: '码', symbol: 'yd', factor: 0.9144 },
    { name: '英里', symbol: 'mi', factor: 1609.344 },
    { name: '海里', symbol: 'nmi', factor: 1852 },
    { name: '里', symbol: '里', factor: 500 },
    { name: '尺', symbol: '尺', factor: 0.3333 },
    { name: '寸', symbol: '寸', factor: 0.03333 }
  ];

  // 面积（基准：平方米）
  private areaUnits: UnitDef[] = [
    { name: '平方厘米', symbol: 'cm²', factor: 0.0001 },
    { name: '平方米', symbol: 'm²', factor: 1 },
    { name: '公顷', symbol: 'ha', factor: 10000 },
    { name: '平方千米', symbol: 'km²', factor: 1000000 },
    { name: '亩', symbol: '亩', factor: 666.667 },
    { name: '平方英尺', symbol: 'ft²', factor: 0.092903 },
    { name: '平方英寸', symbol: 'in²', factor: 0.00064516 },
    { name: '英亩', symbol: 'acre', factor: 4046.86 },
    { name: '平方英里', symbol: 'mi²', factor: 2589988.11 }
  ];

  // 体积（基准：立方米）
  private volumeUnits: UnitDef[] = [
    { name: '立方厘米', symbol: 'cm³', factor: 0.000001 },
    { name: '毫升', symbol: 'mL', factor: 0.000001 },
    { name: '升', symbol: 'L', factor: 0.001 },
    { name: '立方米', symbol: 'm³', factor: 1 },
    { name: '公石', symbol: 'hl', factor: 0.1 },
    { name: '立方英尺', symbol: 'ft³', factor: 0.028317 },
    { name: '加仑(美)', symbol: 'gal', factor: 0.003785 },
    { name: '品脱(美)', symbol: 'pt', factor: 0.0004732 },
    { name: '立方英寸', symbol: 'in³', factor: 0.000016387 }
  ];

  // 重量（基准：千克）
  private weightUnits: UnitDef[] = [
    { name: '毫克', symbol: 'mg', factor: 0.000001 },
    { name: '克', symbol: 'g', factor: 0.001 },
    { name: '千克', symbol: 'kg', factor: 1 },
    { name: '吨', symbol: 't', factor: 1000 },
    { name: '斤', symbol: '斤', factor: 0.5 },
    { name: '两', symbol: '两', factor: 0.05 },
    { name: '磅', symbol: 'lb', factor: 0.453592 },
    { name: '盎司', symbol: 'oz', factor: 0.0283495 }
  ];

  // 进制
  private baseUnits: UnitDef[] = [
    { name: '二进制', symbol: 'BIN', factor: 2 },
    { name: '八进制', symbol: 'OCT', factor: 8 },
    { name: '十进制', symbol: 'DEC', factor: 10 },
    { name: '十六进制', symbol: 'HEX', factor: 16 }
  ];

  // 温度（非线性，特殊处理；factor 仅占位）
  private tempUnits: UnitDef[] = [
    { name: '摄氏度', symbol: '°C', factor: 1 },
    { name: '华氏度', symbol: '°F', factor: 0 },
    { name: '开尔文', symbol: 'K', factor: 0 }
  ];

  // 速度（基准：米每秒）
  private speedUnits: UnitDef[] = [
    { name: '米每秒', symbol: 'm/s', factor: 1 },
    { name: '千米每小时', symbol: 'km/h', factor: 0.277778 },
    { name: '英里每小时', symbol: 'mph', factor: 0.44704 },
    { name: '节', symbol: 'kn', factor: 0.514444 },
    { name: '英尺每秒', symbol: 'ft/s', factor: 0.3048 },
    { name: '马赫', symbol: 'Ma', factor: 340.29 }
  ];

  // 压强（基准：帕斯卡）
  private pressureUnits: UnitDef[] = [
    { name: '帕斯卡', symbol: 'Pa', factor: 1 },
    { name: '千帕', symbol: 'kPa', factor: 1000 },
    { name: '兆帕', symbol: 'MPa', factor: 1000000 },
    { name: '巴', symbol: 'bar', factor: 100000 },
    { name: '标准大气压', symbol: 'atm', factor: 101325 },
    { name: '毫米汞柱', symbol: 'mmHg', factor: 133.322 },
    { name: '磅每平方英寸', symbol: 'psi', factor: 6894.76 }
  ];

  // 功率（基准：瓦）
  private powerUnits: UnitDef[] = [
    { name: '瓦', symbol: 'W', factor: 1 },
    { name: '千瓦', symbol: 'kW', factor: 1000 },
    { name: '兆瓦', symbol: 'MW', factor: 1000000 },
    { name: '公制马力', symbol: 'PS', factor: 735.499 },
    { name: '英制马力', symbol: 'hp', factor: 745.7 },
    { name: '英尺磅每秒', symbol: 'ft·lb/s', factor: 1.35582 }
  ];

  build() {
    Stack() {
      // 底层：原有内容
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
              if (this.currentCategory === '') {
                router.back();
              } else {
                this.currentCategory = '';
              }
            });
          Text(this.currentCategory === '' ? '换算' : this.currentCategory + '换算')
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

        if (this.currentCategory === '') {
          this.buildCategoryGrid();
        } else {
          this.buildConvertDetail();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F2F2F2');

      // 上层：单位选择面板
      if (this.showPicker) {
        this.buildUnitPicker();
      }
    }
    .width('100%')
    .height('100%');
  }

  // 入口网格
  @Builder
  buildCategoryGrid() {
    Scroll() {
      Grid() {
        ForEach(this.categories, (cat: Category) => {
          GridItem() {
            Column() {
              Text(cat.icon)
                .fontSize(36)
                .fontColor('#333333')
                .width(56)
                .height(56)
                .textAlign(TextAlign.Center);
              Text(cat.name)
                .fontSize(16)
                .fontColor('#333333')
                .margin({ top: 8 });
            }
            .width('100%')
            .height(120)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.enterCategory(cat.name);
            });
          }
        }, (c: Category) => c.name);
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(16)
      .columnsGap(16)
      .width('100%')
      .padding(16);
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off);
  }

  // 换算详情
  @Builder
  buildConvertDetail() {
    Column() {
      // 上方卡片
      Column() {
        Row() {
          Text(this.getFromUnitName())
            .fontSize(18)
            .fontColor('#888888');
          Text(' ' + this.getFromUnitSymbol())
            .fontSize(18)
            .fontColor('#888888');
          if (this.showLocIcon(this.fromIndex)) {
            Text(' ◎')
              .fontSize(16)
              .fontColor('#888888');
          }
          Text('  >')
            .fontSize(18)
            .fontColor('#888888');
          Blank();
        }
        .width('100%')
        .onClick(() => {
          this.showUnitPicker(true);
        });
        Text(this.fromValue === '' ? '0' : this.fromValue)
          .fontSize(36)
          .fontColor(this.activeSide === 0 ? '#FF9500' : '#000000')
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 8 })
          .onClick(() => {
            this.activeSide = 0;
          });
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16, top: 16 })
      .alignItems(HorizontalAlign.Start);

      // 交换按钮
      Row() {
        Blank();
        Text('⇅')
          .fontSize(24)
          .fontColor('#333333')
          .width(56)
          .height(56)
          .textAlign(TextAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(28)
          .margin({ right: 16, top: 8, bottom: 8 })
          .onClick(() => {
            this.swapUnits();
          });
      }
      .width('100%');

      // 下方卡片
      Column() {
        Row() {
          Text(this.getToUnitName())
            .fontSize(18)
            .fontColor('#888888');
          Text(' ' + this.getToUnitSymbol())
            .fontSize(18)
            .fontColor('#888888');
          if (this.showLocIcon(this.toIndex)) {
            Text(' ◎')
              .fontSize(16)
              .fontColor('#888888');
          }
          Text('  >')
            .fontSize(18)
            .fontColor('#888888');
          Blank();
        }
        .width('100%')
        .onClick(() => {
          this.showUnitPicker(false);
        });
        Text(this.toValue === '' ? '0' : this.toValue)
          .fontSize(36)
          .fontColor(this.activeSide === 1 ? '#FF9500' : '#000000')
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 8 })
          .onClick(() => {
            this.activeSide = 1;
          });
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16 })
      .alignItems(HorizontalAlign.Start);

      Blank();

      // 数字键盘（固定高度，不被压缩）
      this.buildKeyboard();
    }
    .width('100%')
    .layoutWeight(1);
  }

  // 数字键盘（每行固定高度72，保证完整显示）
  @Builder
  buildKeyboard() {
    if (this.currentCategory === '进制') {
      Column() {
        Row() {
          this.buildBaseKey('7'); this.buildBaseKey('8'); this.buildBaseKey('9'); this.buildActionKey('AC');
        }
        .width('100%').height(72).justifyContent(FlexAlign.SpaceAround);
        Row() {
          this.buildBaseKey('4'); this.buildBaseKey('5'); this.buildBaseKey('6'); this.buildActionKey('del');
        }
        .width('100%').height(72).justifyContent(FlexAlign.SpaceAround);
        Row() {
          this.buildBaseKey('1'); this.buildBaseKey('2'); this.buildBaseKey('3'); this.buildBaseKey('F');
        }
        .width('100%').height(72).justifyContent(FlexAlign.SpaceAround);
        Row() {
          this.buildKey('00'); this.buildBaseKey('0'); this.buildDisabledDot(); this.buildBaseKey('E');
        }
        .width('100%').height(72).justifyContent(FlexAlign.SpaceAround);
        Row() {
          this.buildBaseKey('A'); this.buildBaseKey('B'); this.buildBaseKey('C'); this.buildBaseKey('D');
        }
        .width('100%').height(72).justifyContent(FlexAlign.SpaceAround);
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: this.uiContext.px2vp(this.bottomRectHeight) + 12 });
    } else {
      Column() {
        Row() {
          this.buildKey('7'); this.buildKey('8'); this.buildKey('9'); this.buildActionKey('AC');
        }
        .width('100%').height(72).justifyContent(FlexAlign.SpaceAround);
        Row() {
          this.buildKey('4'); this.buildKey('5'); this.buildKey('6'); this.buildActionKey('del');
        }
        .width('100%').height(72).justifyContent(FlexAlign.SpaceAround);
        Row() {
          this.buildKey('1'); this.buildKey('2'); this.buildKey('3'); this.buildBlankKey();
        }
        .width('100%').height(72).justifyContent(FlexAlign.SpaceAround);
        Row() {
          this.buildKey('00'); this.buildKey('0'); this.buildKey('.'); this.buildBlankKey();
        }
        .width('100%').height(72).justifyContent(FlexAlign.SpaceAround);
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: this.uiContext.px2vp(this.bottomRectHeight) + 12 });
    }
  }

  @Builder
  buildKey(label: string) {
    Text(label)
      .fontSize(26)
      .fontColor('#000000')
      .width(72)
      .height(72)
      .textAlign(TextAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderRadius(36)
      .onClick(() => {
        this.onKeyInput(label);
      });
  }

  @Builder
  buildActionKey(label: string) {
    Text(label === 'del' ? '⌫' : label)
      .fontSize(label === 'del' ? 24 : 22)
      .fontColor('#000000')
      .width(72)
      .height(72)
      .textAlign(TextAlign.Center)
      .backgroundColor('#E5E5E5')
      .borderRadius(36)
      .onClick(() => {
        this.onKeyInput(label);
      });
  }

  @Builder
  buildBaseKey(label: string) {
    Text(label)
      .fontSize(24)
      .fontColor(this.isBaseKeyEnabled(label) ? '#000000' : '#CCCCCC')
      .width(72)
      .height(72)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.isBaseKeyEnabled(label) ? '#FFFFFF' : '#F5F5F5')
      .borderRadius(36)
      .onClick(() => {
        if (this.isBaseKeyEnabled(label)) {
          this.onKeyInput(label);
        }
      });
  }

  @Builder
  buildBlankKey() {
    Text('')
      .width(72)
      .height(72);
  }

  @Builder
  buildDisabledDot() {
    Text('.')
      .fontSize(26)
      .fontColor('#CCCCCC')
      .width(72)
      .height(72)
      .textAlign(TextAlign.Center)
      .backgroundColor('#F5F5F5')
      .borderRadius(36);
  }

  // ========== 逻辑方法 ==========

  private getCurrentUnits(): UnitDef[] {
    switch (this.currentCategory) {
      case '汇率': return this.currencyUnits;
      case '长度': return this.lengthUnits;
      case '面积': return this.areaUnits;
      case '体积': return this.volumeUnits;
      case '重量': return this.weightUnits;
      case '温度': return this.tempUnits;
      case '速度': return this.speedUnits;
      case '压强': return this.pressureUnits;
      case '功率': return this.powerUnits;
      case '进制': return this.baseUnits;
      default: return [];
    }
  }

  private getFromUnitName(): string {
    let units = this.getCurrentUnits();
    if (this.fromIndex < units.length) {
      return units[this.fromIndex].name;
    }
    return '';
  }

  private getFromUnitSymbol(): string {
    let units = this.getCurrentUnits();
    if (this.fromIndex < units.length) {
      return units[this.fromIndex].symbol;
    }
    return '';
  }

  private getToUnitName(): string {
    let units = this.getCurrentUnits();
    if (this.toIndex < units.length) {
      return units[this.toIndex].name;
    }
    return '';
  }

  private getToUnitSymbol(): string {
    let units = this.getCurrentUnits();
    if (this.toIndex < units.length) {
      return units[this.toIndex].symbol;
    }
    return '';
  }

  // 是否显示定位图标（汇率的人民币）
  private showLocIcon(index: number): boolean {
    if (this.currentCategory !== '汇率') {
      return false;
    }
    return this.currencyUnits[index].symbol === 'CNY';
  }

  private enterCategory(name: string): void {
    this.currentCategory = name;
    this.fromValue = '1';
    this.toValue = '';
    this.activeSide = 0;
    if (name === '汇率') {
      this.fromIndex = 1; // 美元
      this.toIndex = 0;   // 人民币
    } else if (name === '长度') {
      this.fromIndex = 2; // 米
      this.toIndex = 7;   // 英里
    } else if (name === '面积') {
      this.fromIndex = 1; // 平方米
      this.toIndex = 2;   // 公顷
    } else if (name === '体积') {
      this.fromIndex = 3; // 立方米
      this.toIndex = 4;   // 公石
    } else if (name === '重量') {
      this.fromIndex = 2; // 千克
      this.toIndex = 7;   // 盎司
    } else if (name === '温度') {
      this.fromIndex = 0; // 摄氏度
      this.toIndex = 1;   // 华氏度
    } else if (name === '速度') {
      this.fromIndex = 1; // km/h
      this.toIndex = 2;   // mph
    } else if (name === '压强') {
      this.fromIndex = 1; // kPa
      this.toIndex = 4;   // atm
    } else if (name === '功率') {
      this.fromIndex = 1; // kW
      this.toIndex = 3;   // 公制马力
    } else if (name === '进制') {
      this.fromIndex = 0; // 二进制
      this.toIndex = 2;   // 十进制
    }
    this.recalc();
  }

  private swapUnits(): void {
    let tmpIdx = this.fromIndex;
    this.fromIndex = this.toIndex;
    this.toIndex = tmpIdx;
    let tmpVal = this.fromValue;
    this.fromValue = this.toValue;
    this.toValue = tmpVal;
    this.recalc();
  }

  private showUnitPicker(isFrom: boolean): void {
    this.pickerSide = isFrom ? 0 : 1;
    this.searchText = '';
    this.showPicker = true;
  }

  private selectUnit(index: number): void {
    if (this.pickerSide === 0) {
      this.fromIndex = index;
    } else {
      this.toIndex = index;
    }
    this.showPicker = false;
    this.recalc();
  }

  // 获取按首字母分组并搜索过滤后的单位列表
  private getGroupedUnits(): Array<UnitGroup> {
    let units = this.getCurrentUnits();
    let search = this.searchText.trim().toLowerCase();
    let filtered: UnitDef[] = [];
    for (let i = 0; i < units.length; i++) {
      let u = units[i];
      if (search === '') {
        filtered.push(u);
        continue;
      }
      if (u.name.toLowerCase().indexOf(search) !== -1
        || u.symbol.toLowerCase().indexOf(search) !== -1
        || (u.enName !== undefined && u.enName.toLowerCase().indexOf(search) !== -1)) {
        filtered.push(u);
      }
    }
    // 按首字母分组
    let groupMap: Map<string, UnitDef[]> = new Map();
    for (let i = 0; i < filtered.length; i++) {
      let u = filtered[i];
      let letter = this.getFirstLetter(u);
      if (!groupMap.has(letter)) {
        groupMap.set(letter, []);
      }
      let arr = groupMap.get(letter) as UnitDef[];
      arr.push(u);
    }
    let keys = Array.from(groupMap.keys()).sort();
    let result: Array<UnitGroup> = [];
    for (let i = 0; i < keys.length; i++) {
      result.push({ letter: keys[i], units: groupMap.get(keys[i]) as UnitDef[] });
    }
    return result;
  }

  private getFirstLetter(u: UnitDef): string {
    if (u.enName !== undefined && u.enName !== '') {
      return u.enName.charAt(0).toUpperCase();
    }
    return u.name.charAt(0);
  }

  private getUnitIndex(unit: UnitDef): number {
    let units = this.getCurrentUnits();
    for (let i = 0; i < units.length; i++) {
      if (units[i].symbol === unit.symbol) {
        return i;
      }
    }
    return -1;
  }

  private isUnitSelected(unit: UnitDef): boolean {
    let idx = this.getUnitIndex(unit);
    if (this.pickerSide === 0) {
      return idx === this.fromIndex;
    }
    return idx === this.toIndex;
  }

  private onUnitRowClick(unit: UnitDef): void {
    let idx = this.getUnitIndex(unit);
    if (idx >= 0) {
      this.selectUnit(idx);
    }
  }

  // 单位选择面板
  @Builder
  buildUnitPicker() {
    Column() {
      // 顶部搜索栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#333333')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.showPicker = false;
          });
        Row() {
          Text('🔍')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ right: 6 });
          TextInput({ placeholder: '搜索单位或货币', text: $$this.searchText })
            .layoutWeight(1)
            .fontSize(15)
            .height(36)
            .backgroundColor(Color.Transparent)
            .margin({ left: 2 });
        }
        .layoutWeight(1)
        .height(36)
        .backgroundColor('#F2F2F2')
        .borderRadius(18)
        .padding({ left: 12, right: 12 });
        Text('取消')
          .fontSize(15)
          .fontColor('#00897B')
          .width(52)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.showPicker = false;
          });
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 4, right: 12 })
      .margin({ top: this.uiContext.px2vp(this.topRectHeight) })
      .backgroundColor('#FFFFFF');

      // 分组列表
      Scroll() {
        Column() {
          ForEach(this.getGroupedUnits(), (group: UnitGroup) => {
            Text(group.letter)
              .fontSize(13)
              .fontColor('#999999')
              .fontWeight(FontWeight.Bold)
              .width('100%')
              .padding({ left: 20, top: 14, bottom: 4 });
            ForEach(group.units, (unit: UnitDef) => {
              this.buildUnitRow(unit);
            }, (u: UnitDef) => u.symbol);
          }, (g: UnitGroup) => g.letter);
        }
        .width('100%');
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#FFFFFF');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }

  @Builder
  buildUnitRow(unit: UnitDef) {
    Row() {
      Column() {
        Text(unit.enName !== undefined ? unit.enName : unit.name)
          .fontSize(16)
          .fontColor('#333333');
        Text(unit.name + ' · ' + unit.symbol)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start);
      Blank();
      if (this.isUnitSelected(unit)) {
        Text('✓')
          .fontSize(20)
          .fontColor('#00897B')
          .fontWeight(FontWeight.Bold);
      }
    }
    .width('100%')
    .height(58)
    .padding({ left: 20, right: 20 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onUnitRowClick(unit);
    });
  }

  private onKeyInput(key: string): void {
    // 获取当前输入方的值
    let currentVal = this.activeSide === 0 ? this.fromValue : this.toValue;

    if (key === 'AC') {
      currentVal = '';
      this.setActiveValue(currentVal);
      this.recalc();
      return;
    }
    if (key === 'del') {
      if (currentVal.length > 0) {
        currentVal = currentVal.substring(0, currentVal.length - 1);
      }
      this.setActiveValue(currentVal);
      this.recalc();
      return;
    }
    if (key === '.') {
      if (this.currentCategory === '进制') {
        return;
      }
      if (currentVal.indexOf('.') !== -1) {
        return;
      }
      if (currentVal === '') {
        currentVal = '0';
      }
    }
    if (key === '00') {
      if (currentVal === '' || currentVal === '0') {
        currentVal = '0';
        this.setActiveValue(currentVal);
        this.recalc();
        return;
      }
    }
    if (currentVal.length >= 20) {
      return;
    }
    currentVal += key;
    this.setActiveValue(currentVal);
    this.recalc();
  }

  private setActiveValue(val: string): void {
    if (this.activeSide === 0) {
      this.fromValue = val;
    } else {
      this.toValue = val;
    }
  }

  private isBaseKeyEnabled(label: string): boolean {
    if (this.currentCategory !== '进制') {
      return false;
    }
    // 输入方是哪一侧，就用哪一侧的进制判断
    let idx = this.activeSide === 0 ? this.fromIndex : this.toIndex;
    let base = this.baseUnits[idx].factor;
    let valid = '0123456789ABCDEF';
    let maxChar = valid.charAt(base - 1);
    return label.charAt(0) <= maxChar;
  }

  // 根据当前输入方，计算另一方的值
  private recalc(): void {
    if (this.currentCategory === '进制') {
      this.recalcBase();
      return;
    }
    let units = this.getCurrentUnits();
    if (this.activeSide === 0) {
      // 上方输入，算下方
      this.toValue = this.convertNormal(this.fromValue, this.fromIndex, this.toIndex, units);
    } else {
      // 下方输入，算上方
      this.fromValue = this.convertNormal(this.toValue, this.toIndex, this.fromIndex, units);
    }
  }

  private convertNormal(input: string, srcIdx: number, dstIdx: number, units: UnitDef[]): string {
    if (input === '' || input === '.') {
      return '';
    }
    let val = Number(input);
    if (isNaN(val)) {
      return '';
    }
    // 温度非线性换算，单独处理
    if (this.currentCategory === '温度') {
      return this.convertTemp(val, srcIdx, dstIdx);
    }
    let baseVal = val * units[srcIdx].factor;
    let result = baseVal / units[dstIdx].factor;
    return this.formatNum(result);
  }

  // 温度换算：先转摄氏度，再转目标
  private convertTemp(val: number, srcIdx: number, dstIdx: number): string {
    let c: number;
    if (srcIdx === 0) {
      c = val; // 摄氏度
    } else if (srcIdx === 1) {
      c = (val - 32) * 5 / 9; // 华氏度
    } else {
      c = val - 273.15; // 开尔文
    }
    let result: number;
    if (dstIdx === 0) {
      result = c;
    } else if (dstIdx === 1) {
      result = c * 9 / 5 + 32;
    } else {
      result = c + 273.15;
    }
    return this.formatNum(result);
  }

  private recalcBase(): void {
    let units = this.baseUnits;
    if (this.activeSide === 0) {
      this.toValue = this.convertBase(this.fromValue, this.fromIndex, this.toIndex, units);
    } else {
      this.fromValue = this.convertBase(this.toValue, this.toIndex, this.fromIndex, units);
    }
  }

  private convertBase(input: string, srcIdx: number, dstIdx: number, units: UnitDef[]): string {
    let srcBase = units[srcIdx].factor;
    let dstBase = units[dstIdx].factor;
    let str = input.toUpperCase();
    if (str === '') {
      return '';
    }
    let valid = '0123456789ABCDEF';
    for (let i = 0; i < str.length; i++) {
      let ch = str.charAt(i);
      let idx = valid.indexOf(ch);
      if (idx === -1 || idx >= srcBase) {
        return '';
      }
    }
    let decimal = parseInt(str, srcBase);
    if (isNaN(decimal)) {
      return '';
    }
    if (dstBase === 10) {
      return decimal.toString();
    } else if (dstBase === 2) {
      return decimal.toString(2).toUpperCase();
    } else if (dstBase === 8) {
      return decimal.toString(8).toUpperCase();
    } else {
      return decimal.toString(16).toUpperCase();
    }
  }

  private formatNum(n: number): string {
    if (isNaN(n) || !isFinite(n)) {
      return '错误';
    }
    if (n === 0) {
      return '0';
    }
    let abs = Math.abs(n);
    if (abs >= 1e12 || (abs < 1e-8 && abs > 0)) {
      return n.toExponential(6).replace(/\.?0+e/, 'e');
    }
    return Number(n.toPrecision(10)).toString();
  }
}
