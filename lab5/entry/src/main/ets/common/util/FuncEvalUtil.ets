// 函数表达式求值工具：支持变量 x，供绘图使用
// 支持 + - * / ^ 与 sin cos tan asin acos atan ln log sqrt abs exp，常量 pi/e

class Token {
  type: string = ''; // num / ident / op / ( / )
  value: string = '';

  constructor(type: string, value: string) {
    this.type = type;
    this.value = value;
  }
}

class FuncEvalUtil {
  // 对外：给定表达式和 x 值，返回 y；出错返回 NaN
  eval(expr: string, x: number): number {
    if (expr === undefined || expr === null || expr.trim() === '') {
      return NaN;
    }
    let normalized = this.normalize(expr);
    let tokens: Token[] = [];
    if (!this.tokenize(normalized, tokens)) {
      return NaN;
    }
    let postfix: Token[] = [];
    if (!this.toPostfix(tokens, postfix)) {
      return NaN;
    }
    return this.evalPostfix(postfix, x);
  }

  // 表达式预处理
  private normalize(expr: string): string {
    let s = expr;
    s = s.replace(/π/g, 'pi');
    s = s.replace(/×/g, '*');
    s = s.replace(/÷/g, '/');
    s = s.replace(/√/g, 'sqrt');
    s = s.replace(/\s+/g, '');
    return s;
  }

  private isDigit(c: string): boolean {
    return c >= '0' && c <= '9';
  }

  private isLetter(c: string): boolean {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
  }

  private tokenize(s: string, out: Token[]): boolean {
    let i = 0;
    while (i < s.length) {
      let c = s.charAt(i);
      if (this.isDigit(c) || c === '.') {
        let start = i;
        let dotCount = 0;
        while (i < s.length && (this.isDigit(s.charAt(i)) || s.charAt(i) === '.')) {
          if (s.charAt(i) === '.') {
            dotCount++;
          }
          i++;
        }
        // 科学计数法 e/E（仅在数字后）
        if (i < s.length && (s.charAt(i) === 'e' || s.charAt(i) === 'E')) {
          let j = i + 1;
          if (j < s.length && (s.charAt(j) === '+' || s.charAt(j) === '-')) {
            j++;
          }
          if (j < s.length && this.isDigit(s.charAt(j))) {
            i = j;
            while (i < s.length && this.isDigit(s.charAt(i))) {
              i++;
            }
          }
        }
        if (dotCount > 1) {
          return false;
        }
        out.push(new Token('num', s.substring(start, i)));
      } else if (this.isLetter(c)) {
        let start = i;
        while (i < s.length && this.isLetter(s.charAt(i))) {
          i++;
        }
        out.push(new Token('ident', s.substring(start, i)));
      } else if (c === '+' || c === '-' || c === '*' || c === '/' || c === '^') {
        out.push(new Token('op', c));
        i++;
      } else if (c === '(') {
        // 隐式乘法：前一个是数字/标识符/右括号时补 *
        if (out.length > 0) {
          let prev = out[out.length - 1];
          if (prev.type === 'num' || prev.type === ')' || (prev.type === 'ident' && !this.isFunction(prev.value))) {
            out.push(new Token('op', '*'));
          }
        }
        out.push(new Token('(', c));
        i++;
      } else if (c === ')') {
        out.push(new Token(')', c));
        i++;
      } else if (c === ',') {
        out.push(new Token('op', ','));
        i++;
      } else {
        // 不认识的字符
        return false;
      }
    }
    // 标识符后紧跟数字/左括号型变量：如 x2（不处理，按非法）
    // 隐式乘法：ident(num/ident) 例如 2pi、xx 中的数字后 ident
    let result: Token[] = [];
    for (let k = 0; k < out.length; k++) {
      if (k > 0) {
        let prev = out[k - 1];
        let cur = out[k];
        if ((prev.type === 'num' && cur.type === 'ident' && !this.isFunction(cur.value))
          || (prev.type === 'ident' && !this.isFunction(prev.value) && cur.type === 'ident' && !this.isFunction(cur.value))
          || (prev.type === ')' && cur.type === 'num')
          || (prev.type === ')' && cur.type === 'ident' && !this.isFunction(cur.value))) {
          result.push(new Token('op', '*'));
        }
      }
      result.push(out[k]);
    }
    out.length = 0;
    for (let k = 0; k < result.length; k++) {
      out.push(result[k]);
    }
    return true;
  }

  private isFunction(name: string): boolean {
    return name === 'sin' || name === 'cos' || name === 'tan'
      || name === 'asin' || name === 'acos' || name === 'atan'
      || name === 'ln' || name === 'log' || name === 'sqrt'
      || name === 'abs' || name === 'exp'
      || name === 'floor' || name === 'ceil';
  }

  private precedence(op: string): number {
    if (op === 'u-') {
      return 5;
    }
    if (op === '^') {
      return 4;
    }
    if (op === '*' || op === '/') {
      return 3;
    }
    if (op === '+' || op === '-') {
      return 2;
    }
    if (op === ',') {
      return 1;
    }
    return 0;
  }

  private isRightAssoc(op: string): boolean {
    return op === '^' || op === 'u-';
  }

  private toPostfix(tokens: Token[], out: Token[]): boolean {
    let stack: Token[] = [];
    let prev: Token | null = null;
    for (let i = 0; i < tokens.length; i++) {
      let t = tokens[i];
      if (t.type === 'num') {
        out.push(t);
      } else if (t.type === 'ident') {
        if (this.isFunction(t.value)) {
          stack.push(t); // 函数入栈
        } else {
          out.push(t); // 变量或常量
        }
      } else if (t.type === '(') {
        stack.push(t);
      } else if (t.type === ')') {
        let found = false;
        while (stack.length > 0) {
          let top = stack[stack.length - 1];
          if (top.type === '(') {
            found = true;
            break;
          }
          out.push(stack.pop() as Token);
        }
        if (!found) {
          return false;
        }
        stack.pop(); // 弹出左括号
        if (stack.length > 0 && stack[stack.length - 1].type === 'ident'
          && this.isFunction(stack[stack.length - 1].value)) {
          out.push(stack.pop() as Token);
        }
      } else if (t.type === 'op') {
        // 一元负号判定
        let op = t.value;
        if (op === '-' && (prev === null || prev.type === 'op' || prev.type === '(')) {
          op = 'u-';
        }
        if (op === '+' && (prev === null || prev.type === 'op' || prev.type === '(')) {
          prev = t;
          continue; // 一元正号忽略
        }
        while (stack.length > 0) {
          let top = stack[stack.length - 1];
          if (top.type === 'op') {
            let topOp = top.value;
            if ((!this.isRightAssoc(op) && this.precedence(topOp) >= this.precedence(op))
              || (this.isRightAssoc(op) && this.precedence(topOp) > this.precedence(op))) {
              out.push(stack.pop() as Token);
            } else {
              break;
            }
          } else if (top.type === 'ident' && this.isFunction(top.value)) {
            out.push(stack.pop() as Token);
          } else {
            break;
          }
        }
        stack.push(new Token('op', op));
      }
      prev = t;
    }
    while (stack.length > 0) {
      let top = stack.pop() as Token;
      if (top.type === '(' || top.type === ')') {
        return false;
      }
      out.push(top);
    }
    return true;
  }

  private evalPostfix(postfix: Token[], x: number): number {
    let stack: number[] = [];
    for (let i = 0; i < postfix.length; i++) {
      let t = postfix[i];
      if (t.type === 'num') {
        stack.push(Number(t.value));
      } else if (t.type === 'ident') {
        if (this.isFunction(t.value)) {
          // 后缀序列中函数位于参数之后，弹一个参数应用
          if (stack.length < 1) {
            return NaN;
          }
          let a = stack.pop() as number;
          stack.push(this.applyFunc(t.value, a));
        } else if (t.value === 'x') {
          stack.push(x);
        } else if (t.value === 'pi') {
          stack.push(Math.PI);
        } else if (t.value === 'e') {
          stack.push(Math.E);
        } else {
          return NaN;
        }
      } else if (t.type === 'op') {
        if (t.value === 'u-') {
          if (stack.length < 1) {
            return NaN;
          }
          let a = stack.pop() as number;
          stack.push(-a);
        } else {
          if (stack.length < 2) {
            return NaN;
          }
          let b = stack.pop() as number;
          let a = stack.pop() as number;
          stack.push(this.applyOp(t.value, a, b));
        }
      }
    }
    if (stack.length !== 1) {
      return NaN;
    }
    return stack[0];
  }

  private applyOp(op: string, a: number, b: number): number {
    if (op === '+') {
      return a + b;
    }
    if (op === '-') {
      return a - b;
    }
    if (op === '*') {
      return a * b;
    }
    if (op === '/') {
      if (b === 0) {
        return NaN;
      }
      return a / b;
    }
    if (op === '^') {
      return Math.pow(a, b);
    }
    return NaN;
  }

  private applyFunc(name: string, a: number): number {
    if (name === 'sin') {
      return Math.sin(a);
    }
    if (name === 'cos') {
      return Math.cos(a);
    }
    if (name === 'tan') {
      return Math.tan(a);
    }
    if (name === 'asin') {
      return Math.asin(a);
    }
    if (name === 'acos') {
      return Math.acos(a);
    }
    if (name === 'atan') {
      return Math.atan(a);
    }
    if (name === 'ln') {
      return Math.log(a);
    }
    if (name === 'log') {
      return Math.log10(a);
    }
    if (name === 'sqrt') {
      return Math.sqrt(a);
    }
    if (name === 'abs') {
      return Math.abs(a);
    }
    if (name === 'exp') {
      return Math.exp(a);
    }
    if (name === 'floor') {
      return Math.floor(a);
    }
    if (name === 'ceil') {
      return Math.ceil(a);
    }
    return NaN;
  }
}

export default new FuncEvalUtil();
