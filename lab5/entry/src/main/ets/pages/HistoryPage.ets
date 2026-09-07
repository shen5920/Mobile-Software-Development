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
import HistoryUtil, { HistoryItem } from '../common/util/HistoryUtil';

@Entry
@Component
struct HistoryPage {
  @State historyList: HistoryItem[] = [];
  uiContext = this.getUIContext();
  @StorageLink('topRectHeight') topRectHeight: number = 0;

  aboutToAppear(): void {
    this.loadHistory();
  }

  onPageShow(): void {
    this.loadHistory();
  }

  private loadHistory(): void {
    this.historyList = HistoryUtil.getHistory();
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Column() {
          Text('←')
            .fontSize(26)
            .fontColor('#000000')
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.back();
        });
        Text('历史记录')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ left: 8 });
        Blank();
        Column() {
          Text('🗑')
            .fontSize(22)
            .fontColor('#333333')
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 8 })
        .onClick(() => {
            if (this.historyList.length > 0) {
              HistoryUtil.clearAll();
              this.loadHistory();
            }
          });
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 8 })
      .margin({ top: this.uiContext.px2vp(this.topRectHeight) });

      if (this.historyList.length === 0) {
        Column() {
          Text('📋')
            .fontSize(64)
            .margin({ bottom: 16 });
          Text('暂无历史记录')
            .fontSize(16)
            .fontColor('#999999');
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        List() {
          ForEach(this.historyList, (item: HistoryItem, index: number) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.expression)
                    .fontSize(16)
                    .fontColor('#888888')
                    .width('100%')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis });
                  Text(item.result)
                    .fontSize(26)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#000000')
                    .width('100%')
                    .margin({ top: 6 });
                  Text(HistoryUtil.formatTime(item.time))
                    .fontSize(13)
                    .fontColor('#BBBBBB')
                    .width('100%')
                    .margin({ top: 6 });
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start);

                // 删除按钮
                Text('✕')
                  .fontSize(18)
                  .fontColor('#999999')
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    HistoryUtil.removeAt(index);
                    this.loadHistory();
                  });
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .margin({ left: 16, right: 16, top: 8, bottom: 8 })
              .onClick(() => {
                // 点击记录，将结果作为参数返回
                router.back();
              });
            }
          }, (item: HistoryItem) => item.time.toString() + item.expression);
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F2');
  }
}
