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

import { CommonConstants } from '../constants/CommonConstants';

class SciCalculateUtil {
  private isDeg: boolean = true;
  private isInv: boolean = false;

  setDegMode(deg: boolean): void {
    this.isDeg = deg;
  }

  setInvMode(inv: boolean): void {
    this.isInv = inv;
  }

  getDegMode(): boolean {
    return this.isDeg;
  }

  getInvMode(): boolean {
    return this.isInv;
  }

  /**
   * 计算科学表达式
   * @param expr 表达式字符串，如 "sin(30)+2^3"
   * @returns 结果字符串，错误返回 "NaN"
   */
  evaluate(expr: string): string {
    if (expr === null || expr === undefined || expr === '') {
      return 'NaN';
    }
    try {
      // 自动补全未闭合的左括号
      let balanced = this.balanceParens(expr);
      // 替换常量 π 和单独的 e（用单词边界避免匹配科学计数法和函数名中的e）
      let processed = balanced.replace(/π/g, '(' + Math.PI.toString() + ')')
        .replace(/\be\b/g, '(' + Math.E.toString() + ')');
      let tokens = this.tokenize(processed);
      let rpn = this.toRPN(tokens);
      let result = this.evalRPN(rpn);
      if (isNaN(result) || !isFinite(result)) {
        return 'NaN';
      }
      return this.formatResult(result);
    } catch (e) {
      return 'NaN';
    }
  }

  // 自动补全未闭合的左括号
  private balanceParens(expr: string): string {
    let depth = 0;
    for (let i = 0; i < expr.length; i++) {
      if (expr.charAt(i) === '(') {
        depth++;
      } else if (expr.charAt(i) === ')') {
        if (depth > 0) {
          depth--;
        }
      }
    }
    let result = expr;
    for (let i = 0; i < depth; i++) {
      result += ')';
    }
    return result;
  }

  /**
   * 分词
   */
  private tokenize(expr: string): string[] {
    let tokens: string[] = [];
    let i = 0;
    let n = expr.length;
    while (i < n) {
      let ch = expr[i];
      if (ch === ' ') {
        i++;
        continue;
      }
      // 数字（含小数）
      if ((ch >= '0' && ch <= '9') || ch === '.') {
        let num = '';
        while (i < n && ((expr[i] >= '0' && expr[i] <= '9') || expr[i] === '.')) {
          num += expr[i];
          i++;
        }
        tokens.push(num);
        continue;
      }
      // 函数名 sin cos tan log ln abs，以及运算符 mod
      if (ch >= 'a' && ch <= 'z') {
        let func = '';
        while (i < n && expr[i] >= 'a' && expr[i] <= 'z') {
          func += expr[i];
          i++;
        }
        tokens.push(func);
        continue;
      }
      // √ 作为函数
      if (ch === '√') {
        tokens.push('sqrt');
        i++;
        continue;
      }
      // 运算符和括号
      if (ch === '+' || ch === '-' || ch === '×' || ch === '÷' || ch === '^' ||
        ch === '!' || ch === '(' || ch === ')') {
        tokens.push(ch);
        i++;
        continue;
      }
      // 百分号
      if (ch === '%') {
        tokens.push('%');
        i++;
        continue;
      }
      i++;
    }
    return tokens;
  }

  /**
   * 获取运算符优先级
   */
  private precedence(op: string): number {
    if (op === '+' || op === '-') return 1;
    if (op === '×' || op === '÷' || op === 'mod') return 2;
    if (op === '^') return 4;
    if (op === '!') return 5;
    return 0;
  }

  private isFunction(token: string): boolean {
    return token === 'sin' || token === 'cos' || token === 'tan' ||
      token === 'log' || token === 'ln' || token === 'sqrt' || token === 'abs' || token === 'exp' ||
      token === 'floor' || token === 'ceil' || token === 'frac' ||
      token === 'sinh' || token === 'cosh' || token === 'tanh' ||
      token === 'asinh' || token === 'acosh' || token === 'atanh' ||
      token === 'asin' || token === 'acos' || token === 'atan';
  }

  private isOperator(token: string): boolean {
    return token === '+' || token === '-' || token === '×' || token === '÷' ||
      token === '^' || token === '!' || token === '%' || token === 'mod';
  }

  /**
   * 调度场算法转后缀表达式
   */
  private toRPN(tokens: string[]): string[] {
    let output: string[] = [];
    let stack: string[] = [];
    let prevToken = '';
    for (let token of tokens) {
      if (this.isNumber(token)) {
        output.push(token);
      } else if (this.isFunction(token)) {
        stack.push(token);
      } else if (token === '(') {
        stack.push(token);
      } else if (token === ')') {
        while (stack.length > 0 && stack[stack.length - 1] !== '(') {
          output.push(stack.pop() as string);
        }
        if (stack.length > 0) stack.pop(); // 弹出 (
        if (stack.length > 0 && this.isFunction(stack[stack.length - 1])) {
          output.push(stack.pop() as string);
        }
      } else if (token === '!' || token === '%') {
        output.push(token);
      } else if (this.isOperator(token)) {
        // 处理负号：如果是表达式开头或前面是运算符或左括号，则为负号
        if (token === '-' && (prevToken === '' || prevToken === '(' || this.isOperator(prevToken))) {
          output.push('0');
        }
        while (stack.length > 0) {
          let top = stack[stack.length - 1];
          if (top === '(') break;
          if (this.isFunction(top)) {
            output.push(stack.pop() as string);
            continue;
          }
          // ^ 右结合
          if (token === '^' && top === '^') break;
          if (this.precedence(top) >= this.precedence(token)) {
            output.push(stack.pop() as string);
          } else {
            break;
          }
        }
        stack.push(token);
      }
      prevToken = token;
    }
    while (stack.length > 0) {
      output.push(stack.pop() as string);
    }
    return output;
  }

  private isNumber(token: string): boolean {
    if (token === '') return false;
    return !isNaN(Number(token));
  }

  /**
   * 求后缀表达式的值
   */
  private evalRPN(rpn: string[]): number {
    let stack: number[] = [];
    for (let token of rpn) {
      if (this.isNumber(token)) {
        stack.push(Number(token));
      } else if (token === '!' || token === '%') {
        let a = stack.pop() as number;
        stack.push(token === '!' ? this.factorial(a) : a / 100);
      } else if (this.isFunction(token)) {
        let a = stack.pop() as number;
        stack.push(this.applyFunction(token, a));
      } else {
        let b = stack.pop() as number;
        let a = stack.pop() as number;
        stack.push(this.applyOp(token, a, b));
      }
    }
    if (stack.length !== 1) return NaN;
    return stack[0];
  }

  private applyOp(op: string, a: number, b: number): number {
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case '×': return a * b;
      case '÷': return b === 0 ? NaN : a / b;
      case '^': return Math.pow(a, b);
      case '%': return a % b;
      case 'mod': return b === 0 ? NaN : a % b;
      default: return NaN;
    }
  }

  private applyFunction(func: string, x: number): number {
    if (this.isInv) {
      switch (func) {
        case 'sin': return this.isDeg ? Math.asin(x) * 180 / Math.PI : Math.asin(x);
        case 'cos': return this.isDeg ? Math.acos(x) * 180 / Math.PI : Math.acos(x);
        case 'tan': return this.isDeg ? Math.atan(x) * 180 / Math.PI : Math.atan(x);
        case 'log': return Math.pow(10, x);
        case 'ln': return Math.exp(x);
        case 'sqrt': return x * x;
        case 'abs': return Math.abs(x);
        case 'exp': return Math.log(x);
        case 'floor': return Math.floor(x);
        case 'ceil': return Math.ceil(x);
        case 'frac': return x - Math.floor(x);
        default: return NaN;
      }
    }
    let val = this.isDeg ? x * Math.PI / 180 : x;
    switch (func) {
      case 'sin': return Math.sin(val);
      case 'cos': return Math.cos(val);
      case 'tan': return Math.tan(val);
      case 'log': return Math.log10(x);
      case 'ln': return Math.log(x);
      case 'sqrt': return x < 0 ? NaN : Math.sqrt(x);
      case 'abs': return Math.abs(x);
      case 'exp': return Math.exp(x);
      case 'floor': return Math.floor(x);
      case 'ceil': return Math.ceil(x);
      case 'frac': return x - Math.floor(x);
      case 'asin': return this.isDeg ? Math.asin(x) * 180 / Math.PI : Math.asin(x);
      case 'acos': return this.isDeg ? Math.acos(x) * 180 / Math.PI : Math.acos(x);
      case 'atan': return this.isDeg ? Math.atan(x) * 180 / Math.PI : Math.atan(x);
      case 'sinh': return Math.sinh(x);
      case 'cosh': return Math.cosh(x);
      case 'tanh': return Math.tanh(x);
      case 'asinh': return Math.asinh(x);
      case 'acosh': return Math.acosh(x);
      case 'atanh': return Math.atanh(x);
      default: return NaN;
    }
  }

  private factorial(n: number): number {
    if (n < 0 || n !== Math.floor(n)) return NaN;
    if (n > 170) return Infinity;
    let result = 1;
    for (let i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  private formatResult(result: number): string {
    if (result === 0) return '0';
    let abs = Math.abs(result);
    if (abs >= 1e16 || (abs < 1e-6 && abs > 0)) {
      return result.toExponential(6).replace(/\.?0+e/, 'e');
    }
    let str = result.toString();
    // 去除浮点误差
    if (str.indexOf('.') !== -1) {
      let rounded = Number(result.toPrecision(12));
      str = rounded.toString();
    }
    return str;
  }
}

export default new SciCalculateUtil();
