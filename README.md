# EdgeGuard · 边缘卫士

在 Linux 机器人、物联网终端和边缘计算设备上部署 Suricata IDS/IPS，通过本地 Web 看板查看告警、阻断、规则命中和设备状态。首个实验平台为 Raspberry Pi 4B。看板资源随项目提供，浏览器无需访问 CDN。

## 工作原理

EdgeGuard 部署在被保护设备上。IDS 模式监听指定网卡，Suricata 将匹配规则的通信写入 EVE 日志。IPS 模式通过 nftables 将选定的业务流量送到 NFQUEUE，由 Suricata 决定放行或阻断。管理电脑使用浏览器查看结果。

```text
设备网卡 → Suricata → EVE 日志 → EdgeGuard 采集服务 → 浏览器看板
                                     ↑
                               CPU、内存、温度
```

看板提供安全总览、告警中心、设备资产、检测规则和引擎健康五个视图。点击环形图图例可以筛选放行或阻断事件，再点规则名称可核对时间、地址、协议、SID 和原始日志。

## 验证状态

Raspberry Pi 4B 原型的六项受控协议实验共记录 69 条告警，其中 10 条为 ICMP 阻断。新设备首次安装从本机实际流量开始统计。打包版本已在树莓派验证默认 IDS 和 IPS 规则能够加载、演示端点返回 HTTP 200；全新系统安装、重启恢复及卸载仍待端到端验收。

## 快速部署

将整个项目目录复制到设备，在该目录中执行以下命令。面向使用 systemd、APT 和 Python 3 的 Debian 系系统。先用 `ip -br -4 addr` 确认设备已有的 IPv4 地址和接口名称。下面的两个示例地址分别替换为**设备地址**和**测试电脑地址**。

```bash
ip -br -4 addr
sudo bash install.sh --device 192.0.2.10 --client 192.0.2.20 --interface eth0 --demo
```

安装程序默认启动 IDS 和新版看板。管理电脑打开 `http://设备IP:8082/`。可加 `--dashboard-port 9082` 更换看板端口。安装需要网络以读取 APT 索引和补齐缺少的依赖。

- **Debian 13 / trixie arm64** 使用随附的 Suricata DEB；已安装的较新版本优先保留。二进制、对应源码及许可证在 [vendor](vendor/)。
- **其他 Debian 系平台** 由目标系统的 APT 源解析 Suricata 和运行依赖。发布前须在目标平台验证 NFQUEUE 支持。
- **启用演示业务**时，`--demo` 提供两个无害的 HTTP 路径。接入现有业务时省略此参数，使用 `--port 端口号` 指定目标 TCP 端口。默认规则匹配明文 HTTP 请求，其他协议需要对应规则。
- 使用可信管理网访问看板。当前看板为只读日志接口，人工确认保存在浏览器本地。现有树莓派实验服务占用默认端口和队列时，请在另一台设备或干净系统验收。

## 验收检测和阻断

在安装时指定的**测试电脑**上访问两个路径。Windows PowerShell 请使用 `curl.exe`。

```bash
curl --noproxy '*' --max-time 3 -i http://192.0.2.10:8080/api/status
curl --noproxy '*' --max-time 3 -i http://192.0.2.10:8080/lab/blocked
```

IDS 下两个请求应返回 HTTP 200，第二个请求触发 SID 1000001。看板选择“最近 1 小时”，点击环形图的“告警放行”查看详情。在**设备**上执行以下命令启用 IPS，再从测试电脑重复请求。

```bash
sudo edgeguard ips
sudo nft list table inet edgeguard
```

IPS 下正常路径应返回 200，标记路径应被阻断。结合客户端结果和对应时间的 EVE `alert.action` 核对。NFQUEUE 42 仅接收指定客户端与目标业务端口之间的双向 TCP 流量；队列采用 bypass。实际检查范围取决于入队条件与所选规则。

## 运行维护

| 操作 | 命令或路径 |
| --- | --- |
| 查看当前模式与服务 | `sudo edgeguard status` |
| 切换为监听模式 | `sudo edgeguard ids` |
| 退出防护并撤销项目队列 | `sudo edgeguard baseline` |
| 服务启动失败 | `journalctl -u edgeguard-engine -u edgeguard-dashboard -n 80 --no-pager` |
| 定制规则 | 编辑 `/etc/edgeguard/ids.rules` 或 `ips.rules`，重新执行相应模式命令 |
| 核对实时告警 | `/var/log/edgeguard/eve.json` |
| 导入实验记录 | 将自己导出的 EVE 告警文件以 `*-alerts.jsonl` 放入 `/var/log/edgeguard/experiment-alerts/`，确保看板服务可读 |
| 卸载 EdgeGuard 服务 | 在项目目录运行 `sudo bash uninstall.sh` |

实时视图读取当前 EVE 文件末尾 2 MiB 内最近一小时的记录；高流量时可能覆盖更短的时间。归档用于保留独立实验的告警。系统使用 systemd 保存引擎启用状态；baseline 会禁用引擎开机启动。卸载保留系统软件包、规则和实验日志。重复安装时保留已有规则；重新配置地址前应备份配置，并在卸载后移走旧的 `/etc/edgeguard`。

## 项目组成

| 文件 | 用途 |
| --- | --- |
| `install.sh`、`configure.py` | 安装依赖和服务，按参数生成设备配置、队列和默认规则 |
| `engine.sh`、`edgeguard`、`systemd/` | 启动引擎、切换模式和清理队列 |
| `dashboard.py`、`dashboard-live.html` | 设备采集、EVE 查询和环形图看板 |
| `demo.py` | 可选的正常业务及测试请求端点 |
| `vendor/` | Debian ARM64 Suricata 发行包、校验值、源码与版权说明 |

EdgeGuard 自有代码沿用 [MIT 许可证](LICENSE)。随附的 Suricata 发行包和其中各组件遵循 [上游及 Debian 版权说明](vendor/COPYRIGHT)。
