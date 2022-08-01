# [FSAVDemo](https://mp.weixin.qq.com/s/w_5pZoeV0GdcFppIpuvVcw)
音频: 采集 → 编码 → 封装 → 解封装 → 解码 → 渲染
视频: 采集 → 编码 → 封装 → 解封装 → 解码 → 渲染

采集：解决数据的来源问题
渲染：解决数据的展示问题
生产：解决数据的加工问题
传输：解决数据如何传播

**采集：音频用麦克风, 视频用摄像头.将物理信息采集成数字信号然后存贮**.
视频采集：
android:Camera
iOS:AVCaptureSession
音频采集：
Android：AudioRecord
iOS：Audio Unit

**渲染：将采集的音视频数据通过解封装, 解码转换成图片和声音**.
视频渲染：
iOS:CoreGraphics, Metal渲染.
android:SurfaceView,TextureView,ImageView
第三方：跨平台openGL
音频渲染：
iOS: AudioQueue, AudioGraph
Android: AudioTrack.

**生产：将采集的音视频经过各种变化生成更有趣或者更统一的可供消费的音视频, 例如画面裁剪, 平移缩放, 滤镜, 贴纸, 人脸大脸磨皮和一些高级特效.音频也有变声, 3A算法等.所有的这些都设计到对音视频的重编码**.
视频生产:
裁剪, 图形变换, 特效, 滤镜, 贴纸, 动画, 编解码.
音频生产:
重采样, 降噪, 回声消除, 混音, 音量均衡, 编解码.

虽然平台也有生产修改音视频的能力, 但是能力有限且不好扩展, 因此业界都是用第三方的软件和算法去充实视频生产.例如：
1.图像处理：OpenGL, OpenCV, libyuv, ffmpeg 等；
2.视频编解码：x264, ffmpeg 等；
3.音频处理： ffmpeg 等；
4.音频编解码：fdkaac, opus, ffmpeg 等.

**传输：将音视频通过网络分发出去，触达用户，实现共享。因此诞生出不同的业务形式：直播，短视频，即时通讯**
**传输的核心就在与传输协议，以下是目前最流行的传输协议**.
1.音视频在传输前，打包协议，如：FLV，ts，mpeg4 等；
2.直播推流，有哪些常见的协议，如：RTMP，RSTP 等；
3.直播拉流，有哪些常见的协议，如：RTMP，HLS，RTSP 等；
4.基于 UDP 的协议有哪些？如：RTP/RTCP，QUIC 等.

## 对于一个小白应该如何去学习音视频开发? 

### 第一步弄懂音视频的基础知识

**音频**：采样率，声道，波形图，采样格式，编码格式：mp4,aac,opus 封装格式：mp3,m4a

**视频:**帧率，码率，分辨率，像素格式，颜色空间，IPB帧，pts，dts，yuv与RGB，位深与色深，封装格式：mp4,flv,hls. 编码格式：h264/h265

**熟练ffmpeg等基本工具的使用**

### 第二步接下来写Demo研究流行的音视频项目：

写一些简单的demo。例如你是android开发你就可以用android平台的接口做音视频采集渲染和播放和转码。

研究一些流行的音视频项目，调试，读源码，尝试搞清楚他们的实现。例如有ffmpeg，ijkplayer，webrtc。

在这个过程中去完善和加深你对格式和基本知识的理解。

### 第三步就是对做一个大型项目来完善整个体系：

例如做个直播程序：设计采集，推流，传输，播放，渲染，特效。并且在每个模块都可以添加扩展。

或者用webrtc去做个通话程序，里面也涉及到以上的过程且可以自己修改代码来扩展。

关注一些业内的技术动向，然后去拓宽自己的技术树。

推荐项目：webrtc，ffmpeg，ijkplayer

推荐书籍：音视频开发进阶 [展晓凯 魏晓红](http://link.zhihu.com/?target=https%3A//book.jd.com/writer/%E5%B1%95%E6%99%93%E5%87%AF%20%E9%AD%8F%E6%99%93%E7%BA%A2_1.html)著

推荐博客：雷霄骅：[leixiaohu的博客_CSDN博客-领域博主](http://link.zhihu.com/?target=http%3A//blog.csdn.net/leixiaohu) 雷神是国内音视频blog第一人。内容详实且简单易懂。

行内动向：公众号：[livevidoestack](http://link.zhihu.com/?target=https%3A//mp.weixin.qq.com/s/m8dt9uWTcGO5vgYJZnSPQg)
