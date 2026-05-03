
# 待做：Steam 服务器代理方案

## 需求
- 手机不开科学上网
- APK 内 WebView 能正常访问并登录 Steam
- 实现 Steam 商店浏览和游戏购买

## 已确认
- ✅ 手机可以不开梯子
- ✅ 手机 4G 直接访问阿里云服务器 (8.153.97.56)
- ✅ 服务器能科学上网（SSH 隧道走 Mac 7890 端口）
- ✅ 不违规（Yann 确认允许）

## 方案（2026-05-03 晚记录）
### Option A: 服务器 HTTP 代理
- 服务器装 tinyproxy/3proxy → 开 8088 端口
- APK WebView 自动走 `http://8.153.97.56:8088` 代理
- 但 Flutter webview_flutter 不支持自定义代理

### Option B: 服务端页面抓取
- 服务器 Python/Node.js 后端抓 Steam 页面
- APK 只展示抓取后的内容
- 登录用 Steam OpenID，服务端中转

### Option C: Android 原生 WebView 自定义代理
- 用 platform channel 调用原生 Android WebView 设置代理
- 需要写一些 Kotlin/Java 代码
- 对应：自己实现一个 WebView widget（不用 webview_flutter）

**2026-05-03 更新：标注为待办，Yann 说"帮我标注这个想法，后面想做 steam 直连用"**
