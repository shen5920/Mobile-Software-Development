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
import SciCalculateUtil from '../common/util/SciCalculateUtil';
import HistoryUtil from '../common/util/HistoryUtil';
import { CommonConstants } from '../common/constants/CommonConstants';

interface KeyButton {
  value: string;
  type: string; // num, op, func, equal, action, toggle
}

@Entry
@Component
struct HomePage {
  @State mode: number = CommonConstants.MODE_NORMAL; // 0普通 1科学
  @State expression: string = '';
  @State previewResult: string = '';
  @State isDeg: boolean = true;
  @State is2nd: boolean = false;
  @State isHyp: boolean = false; // 双曲函数模式
  @State justCalculated: boolean = false;
  @State caretPos: number = 0; // 光标位置
  @State showTrigMenu: boolean = false; // 三角学下拉
  @State showFuncMenu: boolean = false; // 函数下拉
  @State memory: number = 0; // 内存值
  inputController: TextInputController = new TextInputController();
  uiContext = this.getUIContext();
  @StorageLink('topRectHeight') topRectHeight: number = 0;
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0;

  // 普通计算器键盘 4列
  private normalKeys: KeyButton[][] = [
    [{ value: 'AC', type: 'action' }, { value: '%', type: 'action' }, { value: 'del', type: 'action' }, { value: '÷', type: 'op' }],
    [{ value: '7', type: 'num' }, { value: '8', type: 'num' }, { value: '9', type: 'num' }, { value: '×', type: 'op' }],
    [{ value: '4', type: 'num' }, { value: '5', type: 'num' }, { value: '6', type: 'num' }, { value: '-', type: 'op' }],
    [{ value: '1', type: 'num' }, { value: '2', type: 'num' }, { value: '3', type: 'num' }, { value: '+', type: 'op' }],
    [{ value: '00', type: 'num' }, { value: '0', type: 'num' }, { value: '.', type: 'num' }, { value: '=', type: 'equal' }]
  ];

  // 科学计算器键盘 5列 7行（参考截图）
  private sciKeys: KeyButton[][] = [
    [{ value: '2nd', type: 'toggle' }, { value: 'π', type: 'num' }, { value: 'e', type: 'num' }, { value: 'C', type: 'action' }, { value: 'del', type: 'action' }],
    [{ value: 'x²', type: 'special' }, { value: '1/x', type: 'special' }, { value: '|x|', type: 'special' }, { value: 'exp', type: 'sci_func' }, { value: 'mod', type: 'special' }],
    [{ value: '√', type: 'func' }, { value: '(', type: 'num' }, { value: ')', type: 'num' }, { value: '!', type: 'num' }, { value: '÷', type: 'op' }],
    [{ value: 'x^y', type: 'special' }, { value: '7', type: 'num' }, { value: '8', type: 'num' }, { value: '9', type: 'num' }, { value: '×', type: 'op' }],
    [{ value: '10^x', type: 'special' }, { value: '4', type: 'num' }, { value: '5', type: 'num' }, { value: '6', type: 'num' }, { value: '-', type: 'op' }],
    [{ value: 'log', type: 'sci_func' }, { value: '1', type: 'num' }, { value: '2', type: 'num' }, { value: '3', type: 'num' }, { value: '+', type: 'op' }],
    [{ value: 'ln', type: 'sci_func' }, { value: '+/-', type: 'special' }, { value: '0', type: 'num' }, { value: '.', type: 'num' }, { value: '=', type: 'equal' }]
  ];

  build() {
    Column() {
      // 顶部栏（paddingTop 避让状态栏）
      Row() {
        Text('计算器')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ left: 20 });
        Blank();
        // 科学/普通切换
        Text(this.mode === CommonConstants.MODE_NORMAL ? '√π' : '+-')
          .fontSize(16)
          .fontColor('#333333')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.mode = this.mode === CommonConstants.MODE_NORMAL ?
              CommonConstants.MODE_SCIENTIFIC : CommonConstants.MODE_NORMAL;
          })
        // 其他（绘图/日期计算/换算）
        Text('⊞')
          .fontSize(18)
          .fontColor('#333333')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.pushUrl({ url: 'pages/OtherPage' });
          })
        // 历史记录
        Text('⏱')
          .fontSize(16)
          .fontColor('#333333')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .margin({ right: 12 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/HistoryPage' });
          })
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .margin({ top: this.uiContext.px2vp(this.topRectHeight) });

      // 显示区
      Column() {
        TextInput({ text: $$this.expression, placeholder: '0', controller: this.inputController })
          .enableKeyboardOnFocus(false)
          .onTextSelectionChange((start: number, end: number) => {
            this.caretPos = start;
          })
          .fontSize(this.expression.length > 12 ? 36 : 48)
          .fontColor('#000000')
          .textAlign(TextAlign.End)
          .width('100%')
          .height(60)
          .backgroundColor(Color.Transparent)
          .padding({ right: 24, left: 24 })
          .margin({ top: this.mode === CommonConstants.MODE_SCIENTIFIC ? 8 : 40 })
          .placeholderColor('#CCCCCC')
          .defaultFocus(false);

        Text(this.previewResult)
          .fontSize(26)
          .fontColor('#999999')
          .textAlign(TextAlign.End)
          .width('100%')
          .padding({ right: 24, left: 24 })
          .margin({ top: 8, bottom: 16 })
          .maxLines(1);
      }
      .width('100%')
      .height(140)
      .justifyContent(FlexAlign.End);

      // 键盘区
      Column() {
        if (this.mode === CommonConstants.MODE_NORMAL) {
          this.buildKeyboard(this.normalKeys, 4);
        } else {
          this.buildSciKeyboard();
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, bottom: this.uiContext.px2vp(this.bottomRectHeight) + 16, top: 8 })
      .backgroundColor('#F2F2F2');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }

  // 科学计算器完整键盘（状态行+内存+下拉菜单+主键盘）
  @Builder
  buildSciKeyboard() {
    Column() {
      // 状态行：DEG / F-E / 2nd / HYP / M
      Row() {
        Text(this.isDeg ? 'DEG' : 'RAD')
          .fontSize(13)
          .fontColor('#FF9500')
          .margin({ right: 16 })
          .onClick(() => {
            this.isDeg = !this.isDeg;
            SciCalculateUtil.setDegMode(this.isDeg);
            this.updatePreview();
          });
        Text('F-E')
          .fontSize(13)
          .fontColor('#999999');
        if (this.is2nd) {
          Text('2nd')
            .fontSize(13)
            .fontColor('#FF9500')
            .margin({ left: 16 });
        }
        if (this.isHyp) {
          Text('HYP')
            .fontSize(13)
            .fontColor('#FF9500')
            .margin({ left: 16 });
        }
        Blank();
        if (this.memory !== 0) {
          Text('M')
            .fontSize(13)
            .fontColor('#FF9500');
        }
      }
      .width('100%')
      .height(22)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center);

      // 内存键行
      Row() {
        this.buildMemKey('MC');
        this.buildMemKey('MR');
        this.buildMemKey('M+');
        this.buildMemKey('M-');
        this.buildMemKey('MS');
        this.buildMemKey('M⌄');
      }
      .width('100%')
      .height(30)
      .padding({ left: 6, right: 6 });

      // 下拉菜单行
      Row() {
        Row() {
          Text('△')
            .fontSize(13)
            .fontColor('#333333')
            .margin({ right: 4 });
          Text('三角学')
            .fontSize(14)
            .fontColor('#333333');
          Text(this.showTrigMenu ? '▲' : '▼')
            .fontSize(9)
            .fontColor('#999999')
            .margin({ left: 4 });
        }
        .height(30)
        .padding({ left: 10, right: 10 })
        .backgroundColor(this.showTrigMenu ? '#E0E0E0' : '#FFFFFF')
        .borderRadius(8)
        .margin({ right: 8 })
        .onClick(() => {
          this.showTrigMenu = !this.showTrigMenu;
          this.showFuncMenu = false;
        });

        Row() {
          Text('ƒ')
            .fontSize(14)
            .fontColor('#333333')
            .margin({ right: 4 });
          Text('函数')
            .fontSize(14)
            .fontColor('#333333');
          Text(this.showFuncMenu ? '▲' : '▼')
            .fontSize(9)
            .fontColor('#999999')
            .margin({ left: 4 });
        }
        .height(30)
        .padding({ left: 10, right: 10 })
        .backgroundColor(this.showFuncMenu ? '#E0E0E0' : '#FFFFFF')
        .borderRadius(8)
        .onClick(() => {
          this.showFuncMenu = !this.showFuncMenu;
          this.showTrigMenu = false;
        });
        Blank();
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 2, bottom: 2 });

      // 三角学下拉面板
      if (this.showTrigMenu) {
        this.buildTrigPanel();
      }
      // 函数下拉面板
      if (this.showFuncMenu) {
        this.buildFuncPanel();
      }

      // 主键盘
      Column() {
        this.buildKeyboard(this.sciKeys, 5);
      }
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  buildMemKey(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor('#666666')
      .layoutWeight(1)
      .height(28)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.onMemKey(label);
      });
  }

  @Builder
  buildTrigPanel() {
    Column() {
      Row() {
        this.buildPanelKey('2nd', 'trig_toggle');
        this.buildPanelKey('sin', 'trig');
        this.buildPanelKey('cos', 'trig');
        this.buildPanelKey('tan', 'trig');
      }
      .width('100%')
      .layoutWeight(1);
      Row() {
        this.buildPanelKey('hyp', 'trig_toggle');
        this.buildPanelKey('sec', 'trig');
        this.buildPanelKey('csc', 'trig');
        this.buildPanelKey('cot', 'trig');
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height(76)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 8, right: 8, bottom: 4 });
  }

  @Builder
  buildFuncPanel() {
    Row() {
      this.buildPanelKey('|x|', 'func');
      this.buildPanelKey('[x]', 'func');
      this.buildPanelKey('⌈x⌉', 'func');
      this.buildPanelKey('{x}', 'func');
      this.buildPanelKey('rand', 'func');
    }
    .width('100%')
    .height(42)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 8, right: 8, bottom: 4 });
  }

  @Builder
  buildPanelKey(label: string, type: string) {
    Text(label)
      .fontSize(14)
      .fontColor('#333333')
      .layoutWeight(1)
      .height('100%')
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.onPanelKey(label, type);
      });
  }

  private onMemKey(label: string): void {
    if (label === 'MC') {
      this.memory = 0;
    } else if (label === 'MR') {
      this.insertAtCaret(this.memory.toString());
      this.updatePreview();
    } else if (label === 'M+') {
      let val = Number(SciCalculateUtil.evaluate(this.expression));
      if (!isNaN(val)) this.memory += val;
    } else if (label === 'M-') {
      let val = Number(SciCalculateUtil.evaluate(this.expression));
      if (!isNaN(val)) this.memory -= val;
    } else if (label === 'MS') {
      let val = Number(SciCalculateUtil.evaluate(this.expression));
      if (!isNaN(val)) this.memory = val;
    } else if (label === 'M⌄') {
      this.insertAtCaret(this.memory.toString());
      this.memory = 0;
      this.updatePreview();
    }
  }

  private onPanelKey(label: string, type: string): void {
    if (label === '2nd') {
      this.is2nd = !this.is2nd;
      return;
    }
    if (label === 'hyp') {
      this.isHyp = !this.isHyp;
      return;
    }
    if (type === 'trig') {
      if (label === 'sec') {
        this.insertAtCaret('1/cos(');
      } else if (label === 'csc') {
        this.insertAtCaret('1/sin(');
      } else if (label === 'cot') {
        this.insertAtCaret('1/tan(');
      } else {
        // sin/cos/tan，受2nd和hyp影响
        let prefix = '';
        if (this.isHyp && this.is2nd) {
          prefix = 'a' + label + 'h(';
        } else if (this.isHyp) {
          prefix = label + 'h(';
        } else if (this.is2nd) {
          prefix = 'a' + label + '(';
        } else {
          prefix = label + '(';
        }
        this.insertAtCaret(prefix);
      }
      this.updatePreview();
      return;
    }
    if (type === 'func') {
      if (label === '|x|') {
        this.insertAtCaret('abs(');
      } else if (label === '[x]') {
        this.insertAtCaret('floor(');
      } else if (label === '⌈x⌉') {
        this.insertAtCaret('ceil(');
      } else if (label === '{x}') {
        this.insertAtCaret('frac(');
      } else if (label === 'rand') {
        let r = Math.random().toString();
        this.insertAtCaret(r.substring(0, 8));
      }
      this.updatePreview();
    }
  }

  @Builder
  buildKeyboard(keys: KeyButton[][], columns: number) {
    Column() {
      ForEach(keys, (row: KeyButton[]) => {
        Row() {
          ForEach(row, (key: KeyButton) => {
            this.buildKeyButton(key, columns);
          }, (k: KeyButton) => k.value + k.type);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceAround);
      }, (r: KeyButton[]) => JSON.stringify(r));
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceAround);
  }

  @Builder
  buildKeyButton(key: KeyButton, columns: number) {
    Column() {
      if (key.value === 'del') {
        Text('⌫')
          .fontSize(this.getKeyFontSize(key, columns))
          .fontColor(this.getKeyTextColor(key));
      } else if (key.value === '=') {
        Text('=')
          .fontSize(this.getKeyFontSize(key, columns) + 4)
          .fontColor(this.getKeyTextColor(key))
          .fontWeight(FontWeight.Bold);
      } else if (key.value === 'deg') {
        Text(this.isDeg ? 'DEG' : 'RAD')
          .fontSize(this.getKeyFontSize(key, columns))
          .fontColor(this.getKeyTextColor(key));
      } else {
        Text(key.value)
          .fontSize(key.value.length > 1 ? this.getKeyFontSize(key, columns) - 4 : this.getKeyFontSize(key, columns))
          .fontColor(this.getKeyTextColor(key));
      }
    }
    .width(this.getKeySize(columns))
    .height(this.getKeySize(columns))
    .borderRadius(this.getKeySize(columns) / 2)
    .backgroundColor(this.getKeyBgColor(key))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onKeyPress(key.value, key.type);
    });
  }

  private getKeySize(columns: number): number {
    return columns === 4 ? 72 : 48;
  }

  private getKeyFontSize(key: KeyButton, columns: number): number {
    return columns === 4 ? 28 : 15;
  }

  private getKeyBgColor(key: KeyButton): string {
    if (key.type === 'op' || key.type === 'action') {
      return '#E5E5E5';
    }
    if (key.type === 'equal') {
      return this.mode === CommonConstants.MODE_SCIENTIFIC ? '#00897B' : '#FF9500';
    }
    return '#FFFFFF';
  }

  private getKeyTextColor(key: KeyButton): string {
    if (key.type === 'equal') {
      return '#FFFFFF';
    }
    if (key.type === 'func' || key.type === 'sci_func' || key.type === 'special') {
      return '#888888';
    }
    if (key.value === 'deg' && this.isDeg) {
      return '#FF9500';
    }
    if (key.value === '2nd' && this.is2nd) {
      return '#FF9500';
    }
    return '#000000';
  }

  onKeyPress(value: string, type: string): void {
    // 切换类按钮
    if (value === 'deg') {
      this.isDeg = !this.isDeg;
      SciCalculateUtil.setDegMode(this.isDeg);
      this.updatePreview();
      return;
    }
    if (value === '2nd') {
      this.is2nd = !this.is2nd;
      return;
    }

    // AC / C 清空
    if (value === 'AC' || value === 'C') {
      this.expression = '';
      this.caretPos = 0;
      this.inputController.caretPosition(0);
      this.previewResult = '';
      this.justCalculated = false;
      return;
    }

    // del 删除（光标前）
    if (value === 'del') {
      this.deleteAtCaret();
      this.justCalculated = false;
      this.updatePreview();
      return;
    }

    // 等号计算
    if (value === '=') {
      if (this.expression === '') return;
      let result = SciCalculateUtil.evaluate(this.expression);
      if (result !== 'NaN') {
        HistoryUtil.addHistory(this.expression, result);
        this.expression = result;
        this.caretPos = result.length;
        this.inputController.caretPosition(this.caretPos);
        this.previewResult = '';
        this.justCalculated = true;
      } else {
        this.previewResult = '错误';
      }
      return;
    }

    // 如果刚算完，输入数字则重新开始，输入运算符/函数则继续
    if (this.justCalculated) {
      if (type === 'num' && value !== '.' && value !== '(' && value !== ')' &&
        value !== 'π' && value !== 'e' && value !== '!' && value !== '%') {
        this.expression = '';
        this.caretPos = 0;
      }
      this.justCalculated = false;
    }

    // 受 2nd 影响的科学函数
    if (type === 'sci_func') {
      if (this.is2nd) {
        if (value === 'sin') {
          this.insertAtCaret('asin(');
        } else if (value === 'cos') {
          this.insertAtCaret('acos(');
        } else if (value === 'tan') {
          this.insertAtCaret('atan(');
        } else if (value === 'log') {
          this.insertAtCaret('10^(');
        } else if (value === 'ln') {
          this.insertAtCaret('exp(');
        }
      } else {
        this.insertAtCaret(value + '(');
      }
      this.updatePreview();
      return;
    }

    // 普通函数（√）
    if (type === 'func') {
      if (value === '√') {
        this.insertAtCaret('√(');
      } else {
        this.insertAtCaret(value + '(');
      }
      this.updatePreview();
      return;
    }

    // 特殊功能键
    if (type === 'special') {
      if (value === 'x²') {
        this.insertAtCaret('^2');
      } else if (value === '1/x') {
        this.insertAtCaret('^(-1)');
      } else if (value === '|x|') {
        this.insertAtCaret('abs(');
      } else if (value === 'x^y') {
        this.insertAtCaret('^');
      } else if (value === '10^x') {
        this.insertAtCaret('10^(');
      } else if (value === 'mod') {
        this.insertAtCaret('mod');
      } else if (value === '+/-') {
        this.toggleSign();
      }
      this.updatePreview();
      return;
    }

    // 小数点处理
    if (value === '.') {
      if (this.lastNumberHasDot()) {
        return;
      }
    }

    // 连续运算符处理（光标前一个字符）
    if (type === 'op') {
      if (this.expression === '' && value !== '-') {
        return;
      }
      let lastChar = this.charBeforeCaret();
      if ('+-×÷^'.indexOf(lastChar) !== -1) {
        this.deleteAtCaret();
      }
    }

    // 00 处理
    if (value === '00') {
      let lastChar = this.charBeforeCaret();
      if (this.expression === '' || '+-×÷^('.indexOf(lastChar) !== -1) {
        this.insertAtCaret('0');
      } else {
        this.insertAtCaret('00');
      }
      this.updatePreview();
      return;
    }

    this.insertAtCaret(value);
    this.updatePreview();
  }

  // 在光标位置插入文本
  private insertAtCaret(text: string): void {
    let before = this.expression.substring(0, this.caretPos);
    let after = this.expression.substring(this.caretPos);
    this.expression = before + text + after;
    this.caretPos = before.length + text.length;
    this.inputController.caretPosition(this.caretPos);
  }

  // 删除光标前一个字符（函数名整体删）
  private deleteAtCaret(): void {
    if (this.caretPos === 0) return;
    let before = this.expression.substring(0, this.caretPos);
    let after = this.expression.substring(this.caretPos);
    let funcs = ['sin(', 'cos(', 'tan(', 'log(', 'ln(', 'sqrt(', '√(', 'abs(',
      'asin(', 'acos(', 'atan(', '10^(', 'exp(', '^(-1)'];
    for (let i = 0; i < funcs.length; i++) {
      let f = funcs[i];
      if (before.endsWith(f)) {
        before = before.substring(0, before.length - f.length);
        this.expression = before + after;
        this.caretPos = before.length;
        this.inputController.caretPosition(this.caretPos);
        return;
      }
    }
    before = before.substring(0, before.length - 1);
    this.expression = before + after;
    this.caretPos = before.length;
    this.inputController.caretPosition(this.caretPos);
  }

  // 光标前一个字符
  private charBeforeCaret(): string {
    if (this.caretPos === 0) return '';
    return this.expression.charAt(this.caretPos - 1);
  }

  // 光标前的文本
  private textBeforeCaret(): string {
    return this.expression.substring(0, this.caretPos);
  }

  // 切换当前数字的正负号（基于光标位置）
  private toggleSign(): void {
    let text = this.textBeforeCaret();
    if (text === '') {
      this.insertAtCaret('-');
      return;
    }
    let end = text.length;
    let i = end - 1;
    while (i >= 0) {
      let ch = text.charAt(i);
      if ((ch >= '0' && ch <= '9') || ch === '.') {
        i--;
      } else {
        break;
      }
    }
    let numStart = i + 1;
    if (numStart >= end) {
      this.insertAtCaret('-');
      return;
    }
    let after = this.expression.substring(this.caretPos);
    if (numStart > 0 && text.charAt(numStart - 1) === '-') {
      let before = text.substring(0, numStart - 1);
      let num = text.substring(numStart, end);
      this.expression = before + num + after;
      this.caretPos = before.length + num.length;
    } else {
      let before = text.substring(0, numStart);
      let num = text.substring(numStart, end);
      this.expression = before + '-' + num + after;
      this.caretPos = before.length + 1 + num.length;
    }
    this.inputController.caretPosition(this.caretPos);
  }

  private lastNumberHasDot(): boolean {
    let text = this.textBeforeCaret();
    let i = text.length - 1;
    while (i >= 0) {
      let ch = text.charAt(i);
      if (ch === '.') return true;
      if ('+-×÷^()√'.indexOf(ch) !== -1) return false;
      i--;
    }
    return false;
  }

  private updatePreview(): void {
    if (this.expression === '') {
      this.previewResult = '';
      return;
    }
    // 表达式以运算符结尾时，去掉运算符再算
    let expr = this.expression;
    let lastChar = expr.charAt(expr.length - 1);
    while (expr.length > 0 && '+-×÷^'.indexOf(lastChar) !== -1) {
      expr = expr.substring(0, expr.length - 1);
      lastChar = expr.charAt(expr.length - 1);
    }
    if (expr === '') {
      this.previewResult = '';
      return;
    }
    let result = SciCalculateUtil.evaluate(expr);
    if (result === 'NaN') {
      this.previewResult = '';
    } else {
      this.previewResult = result;
    }
  }
}
