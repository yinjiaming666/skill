---
name: "css-scss-guidelines"
description: "提供关于 CSS 和 SCSS 编写的最佳实践和规范。当涉及前端样式编写、布局调整、组件样式重构时，请触发并遵循此技能。"
---

# CSS & SCSS 编写规范 (CSS & SCSS Guidelines)

在进行前端样式编写与组件重构时，请务必严格遵循以下核心规范，以确保代码的统一性、可维护性及纯净的 DOM 结构。

## 1. 语义化与 HTML 标签约束
- **文本专属标签**：默认情况下，所有纯文本内容**必须**使用 `<span>` 标签进行包裹。
- **禁用默认块级标签**：除非有明确的 SEO 或强语义化需求，**严禁使用 `<h1-h6>` 或 `<p>` 标签**。
- **禁用原生列表与表格标签**：无特殊情况，**禁止使用 `<li>`、`<ul>`、`<ol>`、`<table>` 等带有浏览器默认样式的标签**。推荐完全使用 `<div>` 和 `<span>` 配合 CSS（如 Flexbox/Grid）来实现列表与表格布局，彻底消除默认样式干扰。

## 2. 布局与对齐原则
- **Flexbox 优先**：进行元素排列、对齐或居中操作时，**必须优先采用 Flexbox 布局** (`display: flex`)。
- **间距控制**：**强制使用 `gap` 属性** 来控制 Flex 容器内子元素的间距，尽量避免使用 `margin` 或 `padding` 来处理兄弟元素间的空隙。
- **对齐限制**：无特殊情况，**严禁使用 `margin: auto`** 的方式进行对齐或居中。
- **慎用绝对定位**：尽量避免使用绝对定位 (`position: absolute`) 配合负 `margin` 或 `transform` 进行居中，除非是特定的脱离文档流场景（如悬浮徽标、弹窗、Tooltip 等）。

## 3. 背景图处理规范
- **CSS 背景优先**：无特殊情况，背景图**必须使用 CSS `background-image` 实现**，严禁使用绝对定位的 `<img>` 标签作为底层背景。
- **背景属性控制**：配合使用 `background-size: cover` 或 `contain`，以及 `background-position: center` 等属性来精准控制背景图的显示效果与响应式适配。

---

## 代码示例 (Examples)

### ❌ 错误示例 (Bad)
不推荐的标签滥用、冗余的 margin 居中以及 `<img>` 标签背景垫底：

```html
<div class="card-container">
    <img class="bg-img" src="bg.png" alt="background" />
    <h2>核心优势</h2>
    <ul>
        <li class="item">优势一</li>
        <li class="item">优势二</li>
    </ul>
</div>
```

```scss
.card-container {
  position: relative;
  margin: auto; // ❌ 违规：使用 margin: auto 对齐

  .bg-img { // ❌ 违规：使用 img 标签作为背景
    position: absolute;
    width: 100%;
    height: 100%;
    z-index: -1;
  }

  h2 { // ❌ 违规：使用了 h 标签
    color: #333;
    margin-bottom: 20px; // ❌ 违规：使用 margin 控制间距
  }

  ul { // ❌ 违规：使用了自带样式的列表标签
    li.item {
      font-size: 14px;
    }
  }
}
```

### ✅ 正确示例 (Good)
使用纯净的 `<div>` 和 `<span>`，结合 Flexbox 布局与 `gap` 间距，并使用 `background-image`：

```html
<div class="card-container">
    <span class="card-title">核心优势</span>
    <div class="card-list">
        <span class="list-item">优势一</span>
        <span class="list-item">优势二</span>
    </div>
</div>
```

```scss
.card-container {
  display: flex;
  flex-direction: column;
  align-items: center; // ✅ 推荐：使用 Flex 居中对齐
  gap: 20px; // ✅ 推荐：使用 gap 控制间距

  background-image: url('bg.png'); // ✅ 推荐：使用 CSS 背景图
  background-size: cover;
  background-position: center;

  .card-title {
    color: #333;
    font-size: 24px;
    font-weight: bold;
  }

  .card-list {
    display: flex;
    flex-direction: column;
    gap: 10px; // ✅ 推荐：使用 gap 控制列表间距

    .list-item {
      font-size: 14px;
      color: #666;
    }
  }
}
```