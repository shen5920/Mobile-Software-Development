import router from '@ohos.router';
import FuncEvalUtil from '../common/util/FuncEvalUtil';

interface FuncItem {
  id: number;
  expr: string;
  color: string;
  width: number;
}

@Entry
@Component
struct DrawPage {
  uiContext = this.getUIContext();
  @StorageLink('topRectHeight') topRectHeight: number = 0;
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0;

  // 0=坐标视图 1=函数编辑视图
  @State tab: number = 0;
  // 函数列表（默认空，用户手动添加）
  @State funcs: FuncItem[] = [];
  @State selectedId: number = -1;  // 当前键盘编辑的函数
  @State styleId: number = -1;     // 当前展开样式设置的函数
  @State nextId: number = 1;

  // 函数键盘下拉状态
  @State showTrigDrop: boolean = false;
  @State showIneqDrop: boolean = false;
  @State showFuncDrop: boolean = false;
  @State isDraw2nd: boolean = false;
  @State isDrawHyp: boolean = false;

  // 画布（非响应式，手动重绘）
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private zoomScale: number = 28;  // 每单位像素数(px)，onReady 后按密度换算
  private offsetX: number = 0;
  private offsetY: number = 0;
  private inited: boolean = false;

  // 可选颜色
  private colorPool: string[] = ['#1976D2', '#388E3C', '#E53935', '#FB8C00', '#8E24AA', '#00897B'];

  // 函数键盘布局
  private keyRows: string[][] = [
    ['2nd', 'π', 'e', 'C', 'del'],
    ['x²', '1/x', '|x|', 'x', 'y'],
    ['√', '(', ')', '=', '÷'],
    ['x^y', '7', '8', '9', '×'],
    ['10^x', '4', '5', '6', '−'],
    ['log', '1', '2', '3', '+'],
    ['ln', '(-)', '0', '.', 'enter']
  ];

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
        Text('绘图')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ left: 8 });
        Blank();
        // 坐标视图切换
        this.buildTabIcon('坐标', 0);
        // fx 函数编辑切换
        this.buildTabIcon('fx', 1);
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 8, right: 12 })
      .margin({ top: this.uiContext.px2vp(this.topRectHeight) });

      if (this.tab === 0) {
        this.buildCanvasView();
      } else {
        this.buildEditView();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2');
  }

  // 顶部右上角切换图标
  @Builder
  buildTabIcon(label: string, idx: number) {
    Text(label)
      .fontSize(label === 'fx' ? 16 : 14)
      .fontColor(this.tab === idx ? '#FFFFFF' : '#333333')
      .backgroundColor(this.tab === idx ? '#00897B' : '#FFFFFF')
      .borderRadius(8)
      .width(52)
      .height(38)
      .textAlign(TextAlign.Center)
      .margin({ left: 8 })
      .onClick(() => {
        // 切回坐标视图时 Canvas 会重建并在 onReady 中重绘
        this.tab = idx;
      });
  }

  // ============ 坐标视图 ============
  @Builder
  buildCanvasView() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
        .onReady(() => {
          if (!this.inited) {
            this.zoomScale = this.uiContext.vp2px(26);
            this.inited = true;
          }
          this.redraw();
        });

      // 右下角缩放控件
      Column() {
        this.buildZoomBtn('+', () => {
          this.zoomScale *= 1.25;
          this.redraw();
        });
        this.buildZoomBtn('−', () => {
          this.zoomScale /= 1.25;
          this.redraw();
        });
        this.buildZoomBtn('◎', () => {
          this.offsetX = 0;
          this.offsetY = 0;
          this.zoomScale = this.uiContext.vp2px(26);
          this.redraw();
        });
      }
      .margin({ right: 16, bottom: this.uiContext.px2vp(this.bottomRectHeight) + 24 });
    }
    .width('100%')
    .layoutWeight(1);
  }

  @Builder
  buildZoomBtn(label: string, action: () => void) {
    Text(label)
      .fontSize(22)
      .fontColor('#333333')
      .width(48)
      .height(48)
      .textAlign(TextAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .margin({ top: 10 })
      .shadow({ radius: 6, color: '#22000000', offsetX: 0, offsetY: 2 })
      .onClick(() => {
        action();
      });
  }

  // ============ 函数编辑视图 ============
  @Builder
  buildEditView() {
    Column() {
      // 函数列表
      Scroll() {
        Column() {
          ForEach(this.funcs, (item: FuncItem, index?: number) => {
            this.buildFuncRow(item, index === undefined ? 0 : index);
          }, (item: FuncItem) => item.id + '_' + item.expr + '_' + item.color + '_' + item.width);

          // 新增函数行
          Row() {
            Text('f')
              .fontSize(20)
              .fontColor('#FFFFFF')
              .backgroundColor('#9E9E9E')
              .borderRadius(8)
              .width(48)
              .height(48)
              .textAlign(TextAlign.Center);
            Text('输入表达式')
              .fontSize(20)
              .fontColor('#999999')
              .margin({ left: 16 });
            Blank();
          }
          .width('100%')
          .height(64)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.addFunction();
          });
        }
        .width('100%');
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto);

      // 函数键盘
      this.buildFuncKeyboard();
    }
    .width('100%')
    .layoutWeight(1);
  }

  @Builder
  buildFuncRow(item: FuncItem, index: number) {
    Column() {
      Row() {
        Text('f' + (index + 1))
          .fontSize(20)
          .fontColor('#FFFFFF')
          .backgroundColor(item.color)
          .borderRadius(8)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center);
        Text(item.expr === '' ? '输入表达式' : item.expr)
          .fontSize(20)
          .fontColor(item.expr === '' ? '#999999' : '#000000')
          .margin({ left: 16 })
          .layoutWeight(1);
        // 样式设置入口
        Text('样式')
          .fontSize(14)
          .fontColor('#00897B')
          .height(36)
          .padding({ left: 12, right: 12 })
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.selectedId = item.id;
            this.styleId = this.styleId === item.id ? -1 : item.id;
          });
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 8 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.selectedId = item.id;
      });

      // 展开的样式设置区
      if (this.styleId === item.id) {
        this.buildStylePanel(item);
      }
    }
    .width('100%')
    .backgroundColor(this.selectedId === item.id ? '#F5F9FF' : '#FFFFFF');
  }

  @Builder
  buildStylePanel(item: FuncItem) {
    Column() {
      // 颜色选择
      Row() {
        Text('颜色')
          .fontSize(15)
          .fontColor('#666666')
          .width(48);
        ForEach(this.colorPool, (color: string) => {
          Text(color === item.color ? '●' : '○')
            .fontSize(24)
            .fontColor(color)
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.changeColor(item.id, color);
            });
        }, (color: string) => color);
      }
      .width('100%')
      .padding({ left: 16, top: 4, bottom: 4 });

      // 粗细选择
      Row() {
        Text('粗细')
          .fontSize(15)
          .fontColor('#666666')
          .width(48);
        this.buildWidthBtn(item, 2, '细');
        this.buildWidthBtn(item, 3, '中');
        this.buildWidthBtn(item, 5, '粗');
        Blank();
        // 删除
        Text('删除')
          .fontSize(14)
          .fontColor('#E53935')
          .height(36)
          .padding({ left: 12, right: 12 })
          .textAlign(TextAlign.Center)
          .margin({ right: 12 })
          .onClick(() => {
            this.deleteFunction(item.id);
          });
      }
      .width('100%')
      .padding({ left: 16, bottom: 10 });
    }
    .width('100%')
    .backgroundColor('#FAFAFA');
  }

  @Builder
  buildWidthBtn(item: FuncItem, w: number, label: string) {
    Text(label)
      .fontSize(14)
      .fontColor(item.width === w ? '#FFFFFF' : '#333333')
      .backgroundColor(item.width === w ? '#00897B' : '#E8E8E8')
      .borderRadius(14)
      .height(28)
      .padding({ left: 14, right: 14 })
      .textAlign(TextAlign.Center)
      .margin({ right: 10 })
      .onClick(() => {
        this.changeWidth(item.id, w);
      });
  }

  // 函数键盘
  @Builder
  buildFuncKeyboard() {
    Column() {
      // 三个下拉按钮
      Row() {
        this.buildDropBtn('三角学', this.showTrigDrop, 0);
        this.buildDropBtn('不等式', this.showIneqDrop, 1);
        this.buildDropBtn('函数', this.showFuncDrop, 2);
        Blank();
      }
      .width('100%')
      .height(34)
      .padding({ left: 8, right: 8, top: 4 });

      // 下拉面板
      if (this.showTrigDrop) {
        this.buildTrigDropPanel();
      }
      if (this.showIneqDrop) {
        this.buildIneqDropPanel();
      }
      if (this.showFuncDrop) {
        this.buildFuncDropPanel();
      }

      // 主键盘
      Column() {
        ForEach(this.keyRows, (row: string[]) => {
          Row() {
            ForEach(row, (key: string) => {
              this.buildKeyItem(key);
            }, (key: string) => key);
          }
          .width('100%')
          .layoutWeight(1);
        }, (row: string[], idx: number) => idx.toString());
      }
      .layoutWeight(1);
    }
    .width('100%')
    .height(340)
    .padding({ left: 8, right: 8, top: 4, bottom: this.uiContext.px2vp(this.bottomRectHeight) + 6 })
    .backgroundColor('#ECEFF1');
  }

  @Builder
  buildDropBtn(label: string, opened: boolean, idx: number) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#333333');
      Text(opened ? '▲' : '▼')
        .fontSize(9)
        .fontColor('#999999')
        .margin({ left: 4 });
    }
    .height(30)
    .padding({ left: 10, right: 10 })
    .backgroundColor(opened ? '#CFD8DC' : '#FFFFFF')
    .borderRadius(6)
    .margin({ right: 8 })
    .onClick(() => {
      this.onDropBtnClick(idx);
    });
  }

  @Builder
  buildTrigDropPanel() {
    Column() {
      Row() {
        this.buildDropKey('2nd', this.isDraw2nd);
        this.buildDropKey('sin', false);
        this.buildDropKey('cos', false);
        this.buildDropKey('tan', false);
      }
      .width('100%')
      .layoutWeight(1);
      Row() {
        this.buildDropKey('hyp', this.isDrawHyp);
        this.buildDropKey('sec', false);
        this.buildDropKey('csc', false);
        this.buildDropKey('cot', false);
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height(72)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 8, right: 8, top: 4, bottom: 4 });
  }

  @Builder
  buildIneqDropPanel() {
    Row() {
      this.buildDropKey('<', false);
      this.buildDropKey('≤', false);
      this.buildDropKey('=', false);
      this.buildDropKey('≥', false);
      this.buildDropKey('>', false);
    }
    .width('100%')
    .height(38)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 8, right: 8, top: 4, bottom: 4 });
  }

  @Builder
  buildFuncDropPanel() {
    Row() {
      this.buildDropKey('|x|', false);
      this.buildDropKey('[x]', false);
      this.buildDropKey('⌈x⌉', false);
    }
    .width('100%')
    .height(38)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 8, right: 8, top: 4, bottom: 4 });
  }

  @Builder
  buildDropKey(label: string, active: boolean) {
    Text(label)
      .fontSize(14)
      .fontColor(active ? '#00897B' : '#333333')
      .layoutWeight(1)
      .height('100%')
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.onDrawPanelKey(label);
      });
  }

  private onDropBtnClick(idx: number): void {
    if (idx === 0) {
      this.showTrigDrop = !this.showTrigDrop;
      this.showIneqDrop = false;
      this.showFuncDrop = false;
    } else if (idx === 1) {
      this.showIneqDrop = !this.showIneqDrop;
      this.showTrigDrop = false;
      this.showFuncDrop = false;
    } else {
      this.showFuncDrop = !this.showFuncDrop;
      this.showTrigDrop = false;
      this.showIneqDrop = false;
    }
  }

  private onDrawPanelKey(label: string): void {
    if (label === '2nd') {
      this.isDraw2nd = !this.isDraw2nd;
      return;
    }
    if (label === 'hyp') {
      this.isDrawHyp = !this.isDrawHyp;
      return;
    }
    // 找到当前编辑的函数
    let target: FuncItem | null = null;
    for (let i = 0; i < this.funcs.length; i++) {
      if (this.funcs[i].id === this.selectedId) {
        target = this.funcs[i];
      }
    }
    if (target === null) {
      if (this.funcs.length === 0) return;
      target = this.funcs[0];
      this.selectedId = target.id;
    }
    let expr = target.expr;
    if (label === 'sec') {
      expr += '1/cos(';
    } else if (label === 'csc') {
      expr += '1/sin(';
    } else if (label === 'cot') {
      expr += '1/tan(';
    } else if (label === 'sin' || label === 'cos' || label === 'tan') {
      let prefix = '';
      if (this.isDrawHyp && this.isDraw2nd) {
        prefix = 'a' + label + 'h(';
      } else if (this.isDrawHyp) {
        prefix = label + 'h(';
      } else if (this.isDraw2nd) {
        prefix = 'a' + label + '(';
      } else {
        prefix = label + '(';
      }
      expr += prefix;
    } else if (label === '|x|') {
      expr += 'abs(';
    } else if (label === '[x]') {
      expr += 'floor(';
    } else if (label === '⌈x⌉') {
      expr += 'ceil(';
    } else {
      expr += label;
    }
    target.expr = expr;
    this.funcs = this.funcs.slice();
    this.redraw();
  }

  @Builder
  buildKeyItem(key: string) {
    Text(key === 'enter' ? '↵' : key)
      .fontSize(key === 'enter' ? 24 : 18)
      .fontColor(this.getKeyColor(key))
      .backgroundColor(this.getKeyBg(key))
      .borderRadius(10)
      .layoutWeight(1)
      .height('92%')
      .margin(4)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.onFuncKey(key);
      });
  }

  // ============ 画布绘制 ============
  private redraw(): void {
    let ctx = this.context;
    let w = ctx.width;
    let h = ctx.height;
    if (w === 0 || h === 0) {
      return;
    }
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, w, h);

    let cx = w / 2 + this.offsetX;
    let cy = h / 2 + this.offsetY;
    let sc = this.zoomScale;

    // 可见数学范围
    let xMin = (0 - cx) / sc;
    let xMax = (w - cx) / sc;
    let yMin = (cy - h) / sc;
    let yMax = cy / sc;

    let step = this.niceStep(48 / sc);

    // 网格
    ctx.strokeStyle = '#EAEAEA';
    ctx.lineWidth = 1;
    ctx.beginPath();
    let gx = Math.floor(xMin / step) * step;
    while (gx <= xMax) {
      let px = cx + gx * sc;
      ctx.moveTo(px, 0);
      ctx.lineTo(px, h);
      gx += step;
    }
    let gy = Math.floor(yMin / step) * step;
    while (gy <= yMax) {
      let py = cy - gy * sc;
      ctx.moveTo(0, py);
      ctx.lineTo(w, py);
      gy += step;
    }
    ctx.stroke();

    // 坐标轴
    ctx.strokeStyle = '#444444';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(0, cy);
    ctx.lineTo(w, cy);
    ctx.moveTo(cx, 0);
    ctx.lineTo(cx, h);
    ctx.stroke();

    // 轴箭头
    ctx.beginPath();
    ctx.moveTo(w - 2, cy);
    ctx.lineTo(w - 12, cy - 6);
    ctx.moveTo(w - 2, cy);
    ctx.lineTo(w - 12, cy + 6);
    ctx.moveTo(cx, 2);
    ctx.lineTo(cx - 6, 12);
    ctx.moveTo(cx, 2);
    ctx.lineTo(cx + 6, 12);
    ctx.stroke();

    // 刻度数字
    ctx.fillStyle = '#666666';
    ctx.font = this.uiContext.vp2px(11) + 'px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    let lx = Math.floor(xMin / step) * step;
    while (lx <= xMax) {
      if (Math.abs(lx) > step / 1000) {
        let px = cx + lx * sc;
        ctx.fillText(this.fmtLabel(lx), px, cy + 6);
      }
      lx += step;
    }
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';
    let ly = Math.floor(yMin / step) * step;
    while (ly <= yMax) {
      if (Math.abs(ly) > step / 1000) {
        let py = cy - ly * sc;
        ctx.fillText(this.fmtLabel(ly), cx - 8, py);
      }
      ly += step;
    }
    // 原点0
    ctx.textAlign = 'right';
    ctx.textBaseline = 'top';
    ctx.fillText('0', cx - 6, cy + 6);

    // 轴标签
    ctx.fillStyle = '#333333';
    ctx.font = this.uiContext.vp2px(13) + 'px sans-serif';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';
    ctx.fillText('x', w - 16, cy - 14);
    ctx.textAlign = 'center';
    ctx.textBaseline = 'bottom';
    ctx.fillText('y', cx + 12, 14);

    // 函数曲线
    for (let i = 0; i < this.funcs.length; i++) {
      this.drawCurve(ctx, this.funcs[i], w, h, cx, cy, sc);
    }
  }

  private drawCurve(ctx: CanvasRenderingContext2D, func: FuncItem, w: number, h: number,
    cx: number, cy: number, sc: number): void {
    if (func.expr.trim() === '') {
      return;
    }
    ctx.strokeStyle = func.color;
    ctx.lineWidth = func.width;
    ctx.beginPath();
    let penDown = false;
    let lastPy = 0;
    for (let px = 0; px <= w; px += 2) {
      let x = (px - cx) / sc;
      let y = FuncEvalUtil.eval(func.expr, x);
      if (isNaN(y) || !isFinite(y)) {
        penDown = false;
        continue;
      }
      let py = cy - y * sc;
      // 超出屏幕过多或渐近线跳变，抬笔断开
      if (py < -h * 2 || py > h * 3) {
        penDown = false;
        continue;
      }
      if (penDown && Math.abs(py - lastPy) > h) {
        penDown = false;
      }
      if (!penDown) {
        ctx.moveTo(px, py);
        penDown = true;
      } else {
        ctx.lineTo(px, py);
      }
      lastPy = py;
    }
    ctx.stroke();
  }

  private niceStep(raw: number): number {
    if (raw <= 0 || !isFinite(raw)) {
      return 1;
    }
    let pow = Math.pow(10, Math.floor(Math.log10(raw)));
    let n = raw / pow;
    let nice = 10;
    if (n < 1.5) {
      nice = 1;
    } else if (n < 3.5) {
      nice = 2;
    } else if (n < 7.5) {
      nice = 5;
    }
    return nice * pow;
  }

  private fmtLabel(n: number): string {
    let r = Math.round(n * 100000) / 100000;
    return r.toString();
  }

  // ============ 函数列表操作 ============
  private addFunction(): void {
    let color = this.colorPool[this.nextId % this.colorPool.length];
    let item: FuncItem = { id: this.nextId, expr: '', color: color, width: 3 };
    this.funcs.push(item);
    this.funcs = this.funcs.slice();
    this.selectedId = this.nextId;
    this.styleId = -1;
    this.nextId++;
    this.redraw();
  }

  private deleteFunction(id: number): void {
    let list: FuncItem[] = [];
    for (let i = 0; i < this.funcs.length; i++) {
      if (this.funcs[i].id !== id) {
        list.push(this.funcs[i]);
      }
    }
    this.funcs = list;
    this.styleId = -1;
    if (this.selectedId === id && this.funcs.length > 0) {
      this.selectedId = this.funcs[0].id;
    }
    this.redraw();
  }

  private changeColor(id: number, color: string): void {
    for (let i = 0; i < this.funcs.length; i++) {
      if (this.funcs[i].id === id) {
        this.funcs[i].color = color;
      }
    }
    this.funcs = this.funcs.slice();
    this.redraw();
  }

  private changeWidth(id: number, w: number): void {
    for (let i = 0; i < this.funcs.length; i++) {
      if (this.funcs[i].id === id) {
        this.funcs[i].width = w;
      }
    }
    this.funcs = this.funcs.slice();
    this.redraw();
  }

  // ============ 键盘逻辑 ============
  private getKeyBg(key: string): string {
    if (key === 'enter') {
      return '#00897B';
    }
    return '#FFFFFF';
  }

  private getKeyColor(key: string): string {
    if (key === 'enter') {
      return '#FFFFFF';
    }
    if (this.isFuncKey(key)) {
      return '#37474F';
    }
    return '#000000';
  }

  private isFuncKey(key: string): boolean {
    return key === '2nd' || key === 'π' || key === 'e' || key === 'x²' || key === '1/x'
      || key === '|x|' || key === '√' || key === 'x^y' || key === '10^x' || key === 'log'
      || key === 'ln' || key === 'C' || key === 'del' || key === '(-)' || key === 'x' || key === 'y';
  }

  private onFuncKey(key: string): void {
    let target: FuncItem | null = null;
    for (let i = 0; i < this.funcs.length; i++) {
      if (this.funcs[i].id === this.selectedId) {
        target = this.funcs[i];
      }
    }
    if (target === null) {
      if (this.funcs.length === 0) {
        return;
      }
      target = this.funcs[0];
      this.selectedId = target.id;
    }
    let editing: FuncItem = target;
    let expr = editing.expr;

    if (key === 'C') {
      expr = '';
    } else if (key === 'del') {
      // 函数名整体删除
      if (expr.endsWith('sqrt(') || expr.endsWith('log(') || expr.endsWith('ln(')
        || expr.endsWith('sin(') || expr.endsWith('cos(') || expr.endsWith('tan(')
        || expr.endsWith('abs(') || expr.endsWith('floor(') || expr.endsWith('ceil(')
        || expr.endsWith('asin(') || expr.endsWith('acos(') || expr.endsWith('atan(')
        || expr.endsWith('1/cos(') || expr.endsWith('1/sin(') || expr.endsWith('1/tan(')) {
        // 找到最后一个函数名的长度
        let funcs = ['sqrt(', 'log(', 'ln(', 'sin(', 'cos(', 'tan(', 'abs(',
          'floor(', 'ceil(', 'asin(', 'acos(', 'atan(', '1/cos(', '1/sin(', '1/tan('];
        for (let i = 0; i < funcs.length; i++) {
          if (expr.endsWith(funcs[i])) {
            expr = expr.substring(0, expr.length - funcs[i].length);
            break;
          }
        }
      } else if (expr.length > 0) {
        expr = expr.substring(0, expr.length - 1);
      }
    } else if (key === 'enter') {
      this.styleId = -1;
      return;
    } else if (key === '2nd') {
      this.isDraw2nd = !this.isDraw2nd;
      return;
    } else if (key === '=') {
      return;
    } else if (key === 'π') {
      expr += 'pi';
    } else if (key === '×') {
      expr += '*';
    } else if (key === '÷') {
      expr += '/';
    } else if (key === '−') {
      expr += '-';
    } else if (key === 'x²') {
      expr += '^2';
    } else if (key === '1/x') {
      expr += '^(-1)';
    } else if (key === '|x|') {
      expr += 'abs(';
    } else if (key === '√') {
      expr += 'sqrt(';
    } else if (key === 'x^y') {
      expr += '^';
    } else if (key === '10^x') {
      expr += '10^';
    } else if (key === 'log') {
      expr += 'log(';
    } else if (key === 'ln') {
      expr += 'ln(';
    } else if (key === '(-)') {
      expr += '-';
    } else if (key === 'y') {
      expr += 'x';
    } else {
      expr += key;
    }

    editing.expr = expr;
    this.funcs = this.funcs.slice();
    this.redraw();
  }
}
