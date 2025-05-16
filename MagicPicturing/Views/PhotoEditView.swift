//
//  PhotoEditView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

struct PhotoEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: PhotoEditingViewModel
    @State private var currentEditMode: EditingMode = .filter
    @State private var showingSaveOptions = false
    
    // Initialize with an image
    init(image: PlatformImage) {
        _viewModel = StateObject(wrappedValue: PhotoEditingViewModel(image: image))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(currentEditMode.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showingSaveOptions = true
                    }) {
                        Text("完成")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.black)
                
                // Image preview
                #if canImport(UIKit)
                if let image = viewModel.editedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(4/3, contentMode: .fit)
                        .padding(.horizontal)
                        .overlay(
                            Text("无图片")
                                .foregroundColor(.white)
                        )
                }
                #elseif canImport(AppKit)
                if let image = viewModel.editedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(4/3, contentMode: .fit)
                        .padding(.horizontal)
                        .overlay(
                            Text("无图片")
                                .foregroundColor(.white)
                        )
                }
                #endif
                
                // Editing options based on mode
                ScrollView {
                    VStack(spacing: 20) {
                        switch currentEditMode {
                        case .filter:
                            filterOptionsView()
                        case .aiRemove:
                            aiRemoveOptionsView()
                        case .template:
                            templateOptionsView()
                        case .adjust:
                            adjustOptionsView()
                        }
                    }
                    .padding(.bottom, 30)
                }
                
                // Bottom edit tools
                HStack(spacing: 25) {
                    ForEach(EditingMode.allCases, id: \.self) { mode in
                        Button(action: {
                            withAnimation {
                                currentEditMode = mode
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 24))
                                    .foregroundColor(currentEditMode == mode ? .blue : .gray)
                                
                                Text(mode.title)
                                    .font(.system(size: 12))
                                    .foregroundColor(currentEditMode == mode ? .blue : .gray)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black)
            }
        }
        .preferredColorScheme(.dark)
        .actionSheet(isPresented: $showingSaveOptions) {
            ActionSheet(
                title: Text("保存选项"),
                message: Text("选择如何保存您的编辑"),
                buttons: [
                    .default(Text("保存为新照片")) {
                        // Save as new photo
                        saveAsNewPhoto()
                    },
                    .default(Text("覆盖原照片")) {
                        // Overwrite original
                        overwriteOriginal()
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }
    
    // MARK: - Filter Options View
    private func filterOptionsView() -> some View {
        VStack(alignment: .leading) {
            Text("滤镜效果")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(["原图", "清新", "复古", "黑白", "暖色", "冷色", "电影", "梦幻"], id: \.self) { filter in
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(filter)
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.selectedFilter == filter ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            
                            Text(filter)
                                .font(.caption)
                                .foregroundColor(viewModel.selectedFilter == filter ? .blue : .gray)
                        }
                        .onTapGesture {
                            viewModel.applyFilter(named: filter)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Filter intensity slider
            VStack(alignment: .leading) {
                Text("滤镜强度")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.top)
                
                HStack {
                    Text("弱")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Slider(value: $viewModel.filterIntensity, in: 0...1)
                        .accentColor(.blue)
                    
                    Text("强")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
    
    // MARK: - AI Remove Options View
    private func aiRemoveOptionsView() -> some View {
        VStack(alignment: .leading) {
            Text("AI消除")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Text("智能去除照片中不需要的元素")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(["人物", "物体", "文字", "瑕疵"], id: \.self) { item in
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: item == "人物" ? "person.crop.circle.badge.xmark" :
                                            item == "物体" ? "cube.transparent.fill" :
                                            item == "文字" ? "text.badge.xmark" : "bandage")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.selectedAITool == item ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            
                            Text(item)
                                .font(.caption)
                                .foregroundColor(viewModel.selectedAITool == item ? .blue : .gray)
                        }
                        .onTapGesture {
                            viewModel.applyAIRemoval(tool: item)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Text("点击图片上的元素进行智能消除")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 10)
        }
    }
    
    // MARK: - Template Options View
    private func templateOptionsView() -> some View {
        VStack(alignment: .leading) {
            Text("模版构图")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Text("使用专业模板优化照片构图")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(["标准", "人像", "风景", "美食", "产品", "创意"], id: \.self) { template in
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 160)
                                .overlay(
                                    Text(template)
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(viewModel.selectedTemplate == template ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            
                            Text(template)
                                .font(.caption)
                                .foregroundColor(viewModel.selectedTemplate == template ? .blue : .gray)
                        }
                        .onTapGesture {
                            viewModel.applyTemplate(named: template)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Adjust Options View
    private func adjustOptionsView() -> some View {
        VStack(alignment: .leading) {
            Text("调整参数")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                adjustmentSlider(title: "亮度", value: $viewModel.brightness)
                adjustmentSlider(title: "对比度", value: $viewModel.contrast)
                adjustmentSlider(title: "饱和度", value: $viewModel.saturation)
                adjustmentSlider(title: "锐度", value: $viewModel.sharpness)
                adjustmentSlider(title: "色温", value: $viewModel.temperature)
            }
            .padding(.horizontal)
            
            Button(action: {
                viewModel.applyAdjustments()
            }) {
                Text("应用调整")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
    
    // Helper for adjustment sliders
    private func adjustmentSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            HStack {
                Text("-")
                    .foregroundColor(.gray)
                
                Slider(value: value, in: -1...1)
                    .accentColor(.blue)
                
                Text("+")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Save Methods
    
    private func saveAsNewPhoto() {
        // Save as new photo logic
        presentationMode.wrappedValue.dismiss()
    }
    
    private func overwriteOriginal() {
        // Overwrite original logic
        presentationMode.wrappedValue.dismiss()
    }
}

struct PhotoEditView_Previews: PreviewProvider {
    static var previews: some View {
        #if canImport(UIKit)
        PhotoEditView(image: UIImage(systemName: "photo")!)
        #elseif canImport(AppKit)
        PhotoEditView(image: NSImage(named: "photo")!)
        #endif
    }
}
