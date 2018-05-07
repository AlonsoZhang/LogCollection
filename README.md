# LogCollection


用命令行完成对远端计算机的一系列操作，用于不方便使用VNC和批量操作时使用。

首次启动密码为AE Password所生成的密码，有效期为七天。

![logcollection.png](http://www.zhangwu.tech/logcollection.png)

## 各按钮功能
1. Log Path: TMPDIR为系统缓存中的log，Mac Mini重启后会清空。Documents为程序写在本地的log，通常在/Users/gdlocal/Documents/中。
2. Log DateFormat: 默认为第三项(All)None，为打包整个TMPDIR文件夹或者Documents文件夹。当需要按时间下载时可以点击前两项，AE和AP站的格式不同，按需选择。
3. Time Section: 当选择DateFormat之后，该项可以设定所需要的测试log开始和结束的时间，请在原格式上进行修改。
4. Account: 默认为gdlocal，在不改变该tool用途时不需要修改。
5. IP: 填入所需下载log的ip地址，如有多个ip请用逗号“,”分隔。
6. 点击Export，等待下载log，存放于本地的Download文件夹内，Export由灰色变为常态时下载完成。
7. Kill: 强制关闭远端ip活动中的App框内的进程名称，如有多个包含同样名称的进程则会报错。（此操作存在风险，已再加一层密码）
8. Open: 打开App框内地址的程序，默认为桌面上的该App，也可写全地址来打开对应程序。
9. Upload: 将所需上传文件拖到此App窗口，Upload由灰转为常态，点击后上传至对应ip的Downloads文件夹。
10. Remove: 将对应ip的Downloads文件夹清空，并清除所有terminal历史记录。
11. Quick Export: 在Path框内输入远端需复制到本地的文件或文件夹的完整路径，点击Quick Export后快速执行复制指令，存在本地Downloads文件夹内。
12. Screen Capture: 获取对应ip的桌面截图，存在Downloads文件夹内。
13. Open SSH: 打开terminal，进入对应ip的SSH，获得控制权，供手动下指令完成之后动作。

*PS: 关于ip，在NewOpenVNC中点击打开屏幕共享时会自动复制当站ip，点击线名时可以选择复制整条线的ip，供该Tool使用。*
![Openvncip.png](http://www.zhangwu.tech/Openvncip.png)