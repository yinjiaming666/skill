---
name: "css-scss-guidelines"
description: "提供关于 CSS 和 SCSS 编写的最佳实践和规范。当用户涉及前端样式编写、布局调整、组件样式重构时触发此技能。"
---

# CSS & SCSS 编写规范 (CSS & SCSS Guidelines)

在进行前端样式编写时，请严格遵循以下规范：

## 1. 文本标签使用
- 默认情况下，**文字只能使用 `<span>` 标签** 进行包裹。
- 除非有明确的语义化或 SEO 需求，**不得使用 `<h>` 标签 (h1-h6) 或 `<p>` 标签**。

## 2. 布局与对齐方式
- 当需要进行元素的对齐或居中操作时，**优先使用 Flexbox 布局** (`display: flex`)。
- 尽量避免使用绝对定位 (`position: absolute`) 加负 `margin` 或 `transform` 的方式进行居中，除非特殊场景（如悬浮图标、弹窗等）。

## 3. SCSS 嵌套深度
- 编写 SCSS 时，要保持代码的扁平化，避免过度嵌套导致选择器优先级过高且难以维护。
- **SCSS 嵌套尽量不超过 3 层**。如果发现嵌套过深，应考虑通过合理的类名命名（如 BEM 规范）来提取和扁平化样式。

## 示例

**❌ 错误示例 (Bad):**
```html
<!-- 不推荐的标签 -->
<div class="card">
  <h2>标题</h2>
  <p>这是一段描述文本。</p>
</div>
```
```scss
// 嵌套过深
.card {
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
<!-- 推荐的结构 -->
<div class="card">
  <span class="card-title">标题</span>
  <span class="card-desc">这是一段描述文本。</span>
</div>
```
```scss
// 扁平化嵌套，Flex 居中
.card {
  display: flex;
  flex-direction: column;
  align-items: center; // Flex 居中
  
  .card-title {
    color: red;
  }
  
  .card-desc {
    font-size: 14px;
  }
}
```
