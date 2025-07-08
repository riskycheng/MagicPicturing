# 水印样式说明

MagicPicturing 应用现在提供了 9 种不同的水印样式，每种都有独特的设计风格和视觉效果。

## 可用样式

### 1. 经典之框 (Classic)
- **风格**: 传统摄影风格
- **特点**: 白色底部边框，清晰的相机信息和拍摄参数
- **适用**: 专业摄影作品，需要清晰展示技术参数的照片

### 2. 现代之框 (Modern)
- **风格**: 现代简约设计
- **特点**: 简洁的布局，品牌标志突出
- **适用**: 现代感强的照片，商业摄影

### 3. 电影之框 (Film)
- **风格**: 电影胶片风格
- **特点**: 黑色底部边框，电影感色彩调整
- **适用**: 电影感照片，艺术摄影

### 4. 极简风格 (Minimalist)
- **风格**: 极简主义设计
- **特点**: 简洁的线条，角落水印，最小化干扰
- **适用**: 需要突出照片本身的作品，极简风格照片

### 5. 复古风格 (Vintage)
- **风格**: 复古怀旧风格
- **特点**: 胶片穿孔效果，复古色彩调整，怀旧字体
- **适用**: 复古风格照片，怀旧主题作品

### 6. 杂志风格 (Magazine)
- **风格**: 时尚杂志排版
- **特点**: 彩色装饰线条，专业排版，品牌突出
- **适用**: 时尚摄影，杂志风格作品

### 7. 艺术风格 (Artistic)
- **风格**: 艺术创意设计
- **特点**: 艺术边框，装饰元素，温暖色调
- **适用**: 艺术摄影，创意作品

### 8. 科技风格 (Tech)
- **风格**: 未来科技感
- **特点**: 科技网格，霓虹色彩，未来感设计
- **适用**: 科技主题照片，未来感作品

### 9. 自然风格 (Natural)
- **风格**: 有机自然设计
- **特点**: 自然色彩，有机装饰元素，环保主题
- **适用**: 自然摄影，环保主题作品

## 技术特性

所有水印样式都支持：
- **EXIF 数据提取**: 自动提取相机型号、镜头、光圈、快门速度、ISO等信息
- **品牌识别**: 自动识别相机品牌并显示相应标志
- **预览模式**: 支持小尺寸预览和全尺寸渲染
- **响应式设计**: 适配不同尺寸的照片
- **高质量渲染**: 使用 SwiftUI 的 ImageRenderer 进行高质量渲染

## 使用方法

1. 在应用中选择"水印工坊"
2. 选择一张照片
3. 浏览不同的水印样式预览
4. 选择喜欢的样式
5. 查看最终效果并保存

## 自定义选项

每个水印样式都会自动：
- 提取照片的 EXIF 信息
- 识别相机品牌
- 调整布局以适应照片尺寸
- 优化文字大小和间距

## 文件结构

```
PhotoWatermark/
├── Models/
│   ├── WatermarkInfo.swift          # 水印信息数据模型
│   └── WatermarkTemplate.swift      # 水印模板枚举
├── Views/
│   ├── PhotoWatermarkEntryView.swift    # 主入口视图
│   ├── ClassicWatermarkView.swift       # 经典样式
│   ├── ModernWatermarkView.swift        # 现代样式
│   ├── FilmWatermarkView.swift          # 电影样式
│   ├── MinimalistWatermarkView.swift    # 极简样式
│   ├── VintageWatermarkView.swift       # 复古样式
│   ├── MagazineWatermarkView.swift      # 杂志样式
│   ├── ArtisticWatermarkView.swift      # 艺术样式
│   ├── TechWatermarkView.swift          # 科技样式
│   └── NaturalWatermarkView.swift       # 自然样式
├── ViewModels/
│   └── PhotoWatermarkViewModel.swift    # 视图模型
└── Services/
    └── EXIFService.swift                # EXIF 数据提取服务
```

## 扩展说明

要添加新的水印样式：
1. 创建新的 `XXXWatermarkView.swift` 文件
2. 在 `WatermarkTemplate.swift` 中添加新的枚举值
3. 在 `makeView` 方法中添加对应的 case
4. 确保新样式支持 `isPreview` 参数以适配预览模式 