# LYPhotoPickerController
### REQUIREMENTS
最低支持 iOS 8.0
### COMPLETE
* 类似 `UIImagePickerController`的用法（delegate 待完善）
* 多选
	1. 保存多选
	2. 不保存多选
* 排序（多 collection）
* list 标记 (红点待完善)
* 对已选择的预览
* 原图加载
* 实时监听设备"照片"变化
	1. list 的 Add／Delete
	2. 对已选的照片从设备“照片”删除
	3. 在 A Collection 中选择了 A1，同时 A1 还存在于 B Collection 中，在 B Collection 中 删除 A1
	4. 在 browser 界面的时候，当前所对应的list被删除（还有被选中的PHAsset对象）
	4. 很多实现了的功能，待列出来

### TODO：
* 支持 CocoaPods
* iPad 适配
* 原图编辑
* 新增相机
