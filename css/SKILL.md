---
name: "css-scss-guidelines"
description: "提供关于 CSS 和 SCSS 编写的最佳实践和规范。当用户涉及前端样式编写、布局调整、组件样式重构时触发此技能。"
---

# CSS & SCSS 编写规范 (CSS & SCSS Guidelines)

在进行前端样式编写时，请严格遵循以下规范：

## 1. HTML 标签使用
- 默认情况下，**文字只能使用 `<span>` 标签** 进行包裹。
- 除非有明确的语义化或 SEO 需求，**不得使用 `<h>` 标签 (h1-h6) 或 `<p>` 标签**。
- **无特殊情况，不要使用 `<li>`、`<ul>`、`<ol>`、`<table>` 等带有默认样式的 HTML 标签**。推荐使用 `<div>` 和 `<span>` 配合 CSS 来实现列表和表格布局，以避免默认样式带来的干扰。

## 2. 布局与对齐方式
- 当需要进行元素的对齐或居中操作时，**优先使用 Flexbox 布局** (`display: flex`)。
- 尽量避免使用绝对定位 (`position: absolute`) 加负 `margin` 或 `transform` 的方式进行居中，除非特殊场景（如悬浮图标、弹窗等）。

## 3. 背景图处理
- **无特殊情况，背景图优先使用 CSS `background-image` 实现**，而不是使用绝对定位的 `<img>` 标签垫底。
- 配合使用 `background-size: cover` / `contain` 以及 `background-position` 来控制背景图显示效果。

## 4. SCSS 嵌套深度
- 编写 SCSS 时，要保持代码的扁平化，避免过度嵌套导致选择器优先级过高且难以维护。
- **SCSS 嵌套尽量不超过 3 层**。如果发现嵌套过深，应考虑通过合理的类名命名（如 BEM 规范）来提取和扁平化样式。

## 示例

**❌ 错误示例 (Bad):**
```html
<!-- 不推荐的标签及使用 img 作为背景 -->
<div class="card">
  <img class="bg" src="bg.png"  alt=""/>
  <h2>标题</h2>
  <ul>
    <li>列表项1</li>
  </ul>
</div>
```
```scss
// 嵌套过深，使用 img 做背景
.card {
  position: relative;
  .bg {
    position: absolute;
    width: 100%;
    height: 100%;
  }
  .card-header {
    .title-wrapper {
      h2 {
        color: red;
      }
    }
  }
}
```

**✅ 正确示例 (Good):**
```html
<!-- 推荐的结构：纯净标签，背景由 CSS 控制 -->
<div class="card">
  <span class="card-title">标题</span>
  <div class="list">
    <span class="list-item">列表项1</span>
  </div>
</div>
```
```scss
// 扁平化嵌套，Flex 居中，使用 background-image
.card {
  display: flex;
  flex-direction: column;
  align-items: center; // Flex 居中
  background-image: url('bg.png');
  background-size: cover;
  background-position: center;

  .card-title {
    color: red;
  }

  .list {
    display: flex;
    flex-direction: column;

    .list-item {
      font-size: 14px;
    }
  }
}
```
