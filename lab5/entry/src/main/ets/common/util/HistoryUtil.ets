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

export interface HistoryItem {
  expression: string;
  result: string;
  time: number;
}

class HistoryUtil {
  /**
   * 获取所有历史记录
   */
  getHistory(): HistoryItem[] {
    let data = AppStorage.get<HistoryItem[]>(CommonConstants.HISTORY_KEY);
    if (data === null || data === undefined) {
      return [];
    }
    return data;
  }

  /**
   * 添加一条历史记录
   */
  addHistory(expression: string, result: string): void {
    if (expression === '' || result === '' || result === 'NaN' || result === 'error') {
      return;
    }
    let list = this.getHistory();
    let item: HistoryItem = {
      expression: expression,
      result: result,
      time: Date.now()
    };
    list.unshift(item);
    if (list.length > CommonConstants.HISTORY_MAX) {
      list = list.slice(0, CommonConstants.HISTORY_MAX);
    }
    AppStorage.setOrCreate(CommonConstants.HISTORY_KEY, list);
  }

  /**
   * 删除指定索引的记录
   */
  removeAt(index: number): void {
    let list = this.getHistory();
    if (index >= 0 && index < list.length) {
      list.splice(index, 1);
      AppStorage.setOrCreate(CommonConstants.HISTORY_KEY, list);
    }
  }

  /**
   * 清空所有历史记录
   */
  clearAll(): void {
    AppStorage.setOrCreate(CommonConstants.HISTORY_KEY, []);
  }

  /**
   * 格式化时间
   */
  formatTime(time: number): string {
    let date = new Date(time);
    let year = date.getFullYear();
    let month = date.getMonth() + 1;
    let day = date.getDate();
    return year + '/' + month + '/' + day;
  }
}

export default new HistoryUtil();
